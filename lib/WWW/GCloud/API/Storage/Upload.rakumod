use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/uploads-downloads
unit role WWW::GCloud::API::Storage::Upload;

use AttrX::Mooish;
use Cro::HTTP::Client;
use Cro::HTTP::Response;
use WWW::GCloud;
use WWW::GCloud::API;
use WWW::GCloud::Object;
use WWW::GCloud::API::Storage::Upload::Event;
use WWW::GCloud::R::Storage::Object;
use WWW::GCloud::Utils;

also is WWW::GCloud::Object;

has WWW::GCloud::API:D $.api is required;
has WWW::GCloud:D $.gcloud is required;
has WWW::GCloud::R::Storage::Object:D $.meta is required;
has Str:D $.url is required; # The upload URI. For resumables this would be the initial URL.
has IO::Path() $.path;
has IO::Handle $!handle is built;
# When $.segmented data is sent out in segments using a supply.
has Bool:D $.segmented = True;
has UInt $.in-buffer;
has %.query;
has @.headers;
# Same as Cro::HTTP::Client :$timeout
has $.timeout;

has Cro::HTTP::Client:D $.http-client is mooish(:lazy);

# Completed is kept/broken when download is all done, whichever the outcome of it is.
has Promise $.completed is built(False);
has $!completed-vow;
has Supplier $!events .= new;

submethod TWEAK {
    $!handle //= .open(:r, :bin) with $!path;
    $!completed = Promise.new;
    $!in-buffer //= 10*1024*1024;
    $!completed-vow = $!completed.vow;
    %!query<uploadType> = self.upload-type;
}

submethod DESTROY {
    self!close;
}

method build-http-client {
    self.new-http-client(:persistent)
}

method new-http-client(*%c) {
    # Use own serializers/parsers because we'd mostly do some highly-customized requests.
    # Besides, 'multipart/related; boundary=...' is not immediately supported by Cro and
    # causes it to die.
    $.gcloud.http-client.new:
        base-uri => $.url,
        body-serializers => [ Cro::HTTP::BodySerializer::SupplyFallback,
                              Cro::HTTP::BodySerializer::BlobFallback ],
        body-parsers => [ Cro::HTTP::BodyParser::BlobFallback ],
        :!persistent,
        # The API is not expected to issue redirects
        :!follow,
        :http<1.1>,
        |(:$!timeout with $!timeout),
        |%c;
}

method sink { self!close }

method !close {
    my $old;
    cas $!handle, { $old = $_; Nil };
    .close with $old;
}

method upload-type(--> Str:D) {...}
method upload {...}

method progress { $!events.Supply }

method emit-event(Str:D $short-name, |c) {
    $!events.emit: my $ev = WWW::GCloud::API::Storage::Upload::Event.new($short-name, |c);
    $ev
}

has atomicint $!reading = 0;

method !set-reading(\value) {
    $!reading ⚛= value;
 }

method segmented-read(UInt :$from, UInt :$size) {
    supply {
        self!set-reading(1);

        my UInt:D $bsize = $!in-buffer;
        my UInt $offset = $from // (try $!handle.tell);
        my $done = 0;
        # The total amount of data we expect either:
        # - explicitly specified by the caller
        # - unknown if input size is not defined in $.meta.size
        # - otherwise it's no more than bytes between the offset and the total input size
        my $expected = $size // (($.meta.size // Inf) - ($offset // 0));

        $!handle.seek($_, SeekFromBeginning) with $from;

        # # TEST CODE
        # my $sent = 0;
        # my $test-max = (30 * 1024 * 1024).rand.Int;
        # # END TEST CODE

        BUF:
        while ⚛$!reading && $done < $expected {
            my $buf = $!handle.read($bsize);
            my $bytes = $buf.bytes;
            self.emit-event: "BufRead", :$!meta, :$bytes, :$offset, :$from;
            $offset += $bytes with $offset;
            emit $buf;
            last BUF if $bytes < $bsize;

            # # TEST CODE
            # if ($sent += $bytes) > $test-max  {
            #     sleep 5;
            #     die "TEST BROKEN SEGMENTED READ";
            # }
            # # END TEST CODE
        }

        LEAVE self!set-reading(0);
    }
}

# The method will fill a buffer starting from postion at $offset using the segmented-read method
method fill-buffer(Buf:D $body-blob is raw, UInt:D :$offset is copy = 0, UInt :$from, UInt :$size) {
    react whenever self.segmented-read(:$from, :$size) -> $buf {
        my $bytes = $buf.bytes;
        $body-blob.subbuf-rw($offset, $bytes) = $buf;
        $offset += $bytes;
    }

    $body-blob
}

method succeeded(Cro::HTTP::Response:D $response, Mu \AS) {
    my $meta = AS.from-json: await($response.body-text);
    self.emit-event: "Done", :$response, :$meta;
    $!completed-vow.keep($response);
    $meta
}