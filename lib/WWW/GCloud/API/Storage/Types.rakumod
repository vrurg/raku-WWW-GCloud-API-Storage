use v6.e.PREVIEW;
unit module WWW::GCloud::API::Storage::Types;
use experimental :will-complain;

use Method::Also;
use WWW::GCloud::Types;
use WWW::GCloud::API::Storage::X;

subset GCBProjection of Str is export
    will complain { "expected either 'noAcl' or 'full', but got " ~ .gist }
    where Str:U | "noAcl" | "full";

enum GCBResumableKind is export <GCBRKSingle GCBRKMulti>;

subset GCSUriStr is export of Str:D where /^ "gs://" <.wb> /;

# Representation of HTTP Range: header.
our role GCRange {
    method CALL-ME(Numeric:D $num) {
        my proto sub transform(|) {*}
        multi sub transform(WhateverCode:D \wc) { wc.($num) }
        multi sub transform(Inf) { $num }
        multi sub transform(-Inf) { 0 }
        multi sub transform(Numeric:D \n) { n }

        transform($.min) .. transform($.max)
    }
}

# GCSUri is limited to `gs://`-only scheme
class GCSUri is GCUri is export {
    submethod TWEAK {
        # When scheme is not defined the URI is considered relative.
        with self.scheme {
            WWW::GCloud::API::Storage::X::NonGCSUri.new(
                    :uri(self.Str),
                    :when("used to create an instance of " ~ self.^name) ).throw
                if $_ ne 'gs';
        }
    }
    multi method COERCE(GCSUriStr $gcs-uri) { self.parse: $gcs-uri }
    multi method COERCE(Str:D $uri) {
        WWW::GCloud::API::Storage::X::NonGCSUri.new(:$uri, :when("in coercion into " ~ self.^name)).throw
    }

    method parse(Str() $uri, |c) {
        unless $uri ~~ GCSUriStr {
            WWW::GCloud::API::Storage::X::NonGCSUri.new(
                :$uri,
                :when("passed to the  method 'parse' of " ~ self.^name)
            ).throw
        }
        nextsame
    }

    method object(Str $path = self.path) is also<object-name> {
        $path
            andthen (.chars < 2
                        ?? $_
                        !! (IO::Spec::Unix.is-absolute($_)
                            ?? IO::Spec::Unix.abs2rel($_, "/")
                            !! IO::Spec::Unix.canonpath($_))
                            ~ (.ends-with("/") ?? "/" !! ""))
            orelse Nil
    }

    method basename(::?CLASS:D:) {
        $.path andthen IO::Spec::Unix.basename($_) orelse Nil
    }

    method bucket(::?CLASS:D:) { $.authority }

    method is-folder(::?CLASS:D:) { self.path.ends-with("/") }
}