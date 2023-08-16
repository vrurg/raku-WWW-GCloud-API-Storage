use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/resumable-uploads
unit class WWW::GCloud::API::Storage::Upload::Resumable;

use Cro::HTTP::Exception;
use WWW::GCloud::API::Storage::Types;
use WWW::GCloud::API::Storage::Upload;
use WWW::GCloud::API::Storage::X;
use WWW::GCloud::R::Storage::Object;
use WWW::GCloud::Utils;
use WWW::GCloud::X;

also does WWW::GCloud::API::Storage::Upload;

has Str:D $.upload-type is built(False) = "resumable";

# If chunked/streamed upload is requested
has UInt $.chunk-size;
has Bool:D $.is-chunked = ?$!chunk-size;
has UInt:D $.retries = 10;
# Seconds to wait between retries;
has Real:D $.retry-in = 1;
has @.failures;

# Should we automaticall cancel any upload would a resume be aborted?
has Bool:D $.auto-cancel = True;

has $!session-uri;

proto method upload(|) {*}
multi method upload(::AS WWW::GCloud::Record :as($) is raw = WWW::GCloud::R::Storage::Object --> Promise:D) {
    %!query<name>:delete;

    my $body = $.meta.to-json.encode('latin-1');

    $.http-client.post(
        $.url,
        content-type => 'application/json',
        headers => [
            $.gcloud.http-auth-header,
        ],
        :%!query,
        :$body )
    .andthen({
        my $ex;
        my $response =
            await
                self.initial( .result, ($.is-chunked ?? GCBRKMulti !! GCBRKSingle) )
                    .orelse({ $ex = .cause });
        .rethrow with $ex;
        self.succeeded: $response, AS
    })
    .orelse({
        if $.auto-cancel {
            try await self.cancel;
        }
        given .cause {
            $!completed-vow.break($_);
            .rethrow
        }
    })
}

proto method initial(Cro::HTTP::Response:D, GCBResumableKind, |) {*}

multi method initial(Cro::HTTP::Response:D $response, GCBRKMulti) {
    self.throw: WWW::GCloud::X::NYI, :feature('multi-chunk resumable upload')
}

multi method initial(Cro::HTTP::Response:D $response, GCBRKSingle) {
    $!session-uri = my Str:D $ = $response.header('Location');

    my $body;
    my UInt:D $content-length = $!meta.size;

    # Use segmented approach too whenever the exact size is not known
    if $.segmented {
        $body = self.segmented-read;
    }
    else {
        $body = self.fill-buffer: Buf[uint8].allocate($content-length);
    }

    $.http-client.put(
        $!session-uri,
        headers => [
            'Content-Length' => $content-length,
        ],
        :$body )
    .orelse({
        self!fail(.cause);
        self.resume
    })
}

method state {
    $.api.wrap-response(
        :raw,
        $.http-client.put(
            $!session-uri,
            headers => [
                'Content-Length' => 0,
                'Content-Range' => 'bytes */' ~ ($.meta.size // '*'),
            ]),
            body => Buf[uint8].allocate(0) )
}

method resume {
    my $response;
    # Keeps the $from position from the last try.
    my $last-from;

    TRY:
    loop {
        if @.failures > $.retries {
            self.throw: WWW::GCloud::API::Storage::X::OutOfAttempts, :@!failures, :$.meta;
        }

        sleep $.retry-in;

        my $range = await self.state
                            .andthen({
                                $range = self!range-from-response( $response = .result );
                            })
                            .orelse({
                                self!fail(.cause);
                                Nil
                            });

        my $from = ($range andthen .max + 1 orelse $last-from // -1);

        self.emit-event: "Retry", :attempt(+@.failures), :$.meta, :$from;

        # When we can't obtain the range from the server then Nil is signalling a problem and we count it as a failed
        # attempt. Retry.
        next TRY without $range;

        # If $range is boolean True then the download is successfull and we're done!
        last TRY if $range;

        my $body;
        my $size = $.meta.size - $from;
        my $range-value = 'bytes ' ~ $from ~ "-" ~ ($.meta.size - 1) ~ "/" ~ $.meta.size;

        # Have we proceed any further since the last failure?
        if ($last-from andthen $from > $_) {
            # Reset the failure status
            @!failures = ();
        }
        $last-from = $from;

        if $.segmented {
            $body = self.segmented-read(:$from, :$size);
        }
        else {
            $body = self.fill-buffer: Buf[uint8].allocate($size), :$from, :$size;
        }

        # Submit resume request. If succeed with with 200 or 201 then we're done. Any other code, even if success,
        # is considered an error. ResumableStatusCode thrown within .andelse would be intercepted by .orelse and
        # treated as any other error.
        last TRY
            if await $.api.wrap-response(
                        :raw,
                        $.http-client.put(
                            $!session-uri,
                            headers => [
                                'Content-Length' => $size,
                                'Content-Range' => $range-value,
                            ],
                            :$body ))
                        .andthen({
                            unless ($response = .result).status == 200 | 201 {
                                self.throw: WWW::GCloud::API::Storage::X::ResumableStatusCode, :$.meta, :$response
                            }
                            True
                        })
                        .orelse({
                            self!fail(.cause);
                            False
                        });
    }

    $response
}

method cancel {
    $.api.wrap-response(
        :raw,
        $.http-client.delete(
            $!session-uri,
            headers => [ 'Content-Length' => 0 ] )
        .orelse({
            my $ex = .cause;
            # Code 499 means successfull cancellation. Anything else is an unexpected error.
            $ex.rethrow unless $ex ~~ X::Cro::HTTP::Error::Client && $ex.response.status == 499;
            $ex.response
        } ))
}

method !fail($cause) {
    self!set-reading(0); # If there is currently active .segmented-read this will cause it to stop.
    @.failures.push: $cause;
    self.emit-event: "Fail", :$cause, :response($cause.?response), :$.meta;
}

# Don't use the magic of transforming `0..*-20` into a single WhateverCode object but create an explicit Range, no
# matter if only one or both of min/max are special values. This makes the result always work with a single argument
# when invoked because otherwise `*+0 .. *+0` requires two arguments.
method !range($min, $max) { Range.new($min, $max) does WWW::GCloud::API::Storage::Types::GCRange }

method !range-from-response(Cro::HTTP::Response:D $response) {
    given $response.status {
        when 200 | 201 {
            # Both Inf means we're done
            self!range(Inf, Inf) but True
        }
        when 308 {
            my $range;
            with $response.header('Range') -> $rhdr {
                if $rhdr.starts-with('-') {
                    $range = self!range(* + .Int, *);
                }
                elsif $rhdr.ends-with('-') {
                    $range = self!range(.Int, *);
                }
                else {
                    $range = self!range( | $rhdr.split('-').map(*.Int) );
                }
            }
            else {
                # Restart the download from scratch!
                # Since we must resume from the max+1 byte then -1 is the best indicator of starting from 0.
                $range = self!range(*, -1)
            }
            # 308 means "incomplete". Hence – False
            $range but False
        }
        default {
            self.throw: WWW::GCloud::API::Storage::X::ResumableStatusCode, :$response, :$.meta
        }
    }
}