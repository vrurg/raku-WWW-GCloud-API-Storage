use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/uploading-objects
# This module implements JSON API multipart upload.
unit class WWW::GCloud::API::Storage::Upload::Simple;

use Cro::HTTP::BodySerializers;
use WWW::GCloud::API::Storage::Upload;
use WWW::GCloud::Utils;

also does WWW::GCloud::API::Storage::Upload;

has Str:D $.upload-type is built(False) = "multipart";

subset BodyData of Any where Any:U | Str:D | Blob:D;

has BodyData $.body;

submethod TWEAK {
    if $!body ~~ Str:D {
        $!body .= encode("latin-1");
    }

    with $!body {
        with $!meta.size {
            if $!body.bytes != $_ {
                WWW::GCloud::API::Storage::X::SizeMismatch.new(
                    :name($!meta.name), :expected($!meta.size), :got($!body.bytes),
                    where => "provided body blob object"
                ).throw
            }
        }
        else {
            $!meta .= clone( size => $!body.bytes )
        }
    }
}

proto method upload(|) {*}
multi method upload(::AS WWW::GCloud::Record :as($) is raw = WWW::GCloud::R::Storage::Object --> Promise:D) {
    my $boundary = gen-mime-boundary;
    my $body-boundary = '--' ~ $boundary;

    %!query<name>:delete;

    my sub blobify(*@s) {
        @s.join("\r\n").encode("latin-1")
    }

    my Blob[uint8] $body-start = blobify( $body-boundary,
                                          "Content-Type: application/json; charset=UTF-8",
                                          "",
                                          $.meta.to-json,
                                          "",
                                          $body-boundary,
                                          "Content-Type: " ~ $.meta.content-type,
                                          "\r\n" );
    my $start-bytes = $body-start.bytes;
    my Blob[uint8] $body-end = blobify("", $body-boundary, "");

    my $body-length = ($body-start.bytes + $body-end.bytes + $!meta.size);

    my constant AS-SUPPLY = True;

    my $body;

    with $!body {
        my Buf[uint8] $body-blob .= allocate($body-length);

        # Store the generated body parts.
        $body-blob.subbuf-rw(0, $start-bytes) = $body-start;
        $body-blob.subbuf-rw($start-bytes, $!meta.size) = $!body;
        $body-blob.subbuf-rw($start-bytes + $!meta.size, $body-end.bytes) = $body-end;

        $body = $body-blob;
    }
    elsif $.segmented {
        $body = supply {
            emit $body-start;

            whenever self.segmented-read(:from(0)) -> $buf {
                emit $buf;
                LAST emit $body-end;
            }

        }
    }
    else {
        my Buf[uint8] $body-blob .= allocate($body-length);

        # Store the generated body parts.
        $body-blob.subbuf-rw(0, $start-bytes) = $body-start;
        $body-blob.subbuf-rw($start-bytes + $!meta.size, $body-end.bytes) = $body-end;

        my $offset = $start-bytes;

        $body = self.fill-buffer($body-blob, :offset($start-bytes));
    }

    $.http-client.post(
        $.url,
        headers => [
            $.gcloud.http-auth-header,
            |@.headers,
            'Content-Type' => 'multipart/related; boundary=' ~ $boundary,
            'Content-Length' => ($body-start.bytes + $body-end.bytes + $!meta.size),
        ],
        :%!query,
        :$body )
    .andthen({
        self.succeeded: .result, AS
    })
    .orelse({
        $!completed-vow.break(my $cause = .cause);
        $cause.rethrow
    })
}