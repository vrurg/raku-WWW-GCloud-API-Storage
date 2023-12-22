use v6.e.PREVIEW;
use Cro::HTTP::Response;
use WWW::GCloud;
use WWW::GCloud::Types;
use WWW::GCloud::API::Storage;
use WWW::GCloud::API::Storage::Types;

my $gcloud = WWW::GCloud.new;
my $objects = $gcloud.storage.objects;

my sub download(Promise:D $get, $into, :$quiet) {
    note "Downloading into '$into'";
    await $get
        .andthen({
            if $quiet {
                await .result.send-to($into, :close, :!overwrite);
            }
            else {
                react whenever .result.send-to($into, :close, :!overwrite) {
                    $*ERR.print: .total-received, " / ", .response.length, "\r";
                }
                note "";
            }
        })
        .orelse({ note .cause; .cause.rethrow })
}

multi sub MAIN(Str:D $bucket, Str:D $object, IO::Path(Str) :$o, Bool :q(:$quiet)) {
    download( $objects.get($bucket, $object, :media),
              $o // IO::Spec::Unix.basename($object),
              :$quiet )
}

multi sub MAIN(GCSUri:D(GCSUriStr) $uri, IO::Path(Str) :$o, Bool :q(:$quiet)) {
    download( $objects.get($uri, :media),
              $o // IO::Spec::Unix.basename($uri.path),
              :$quiet )
}
