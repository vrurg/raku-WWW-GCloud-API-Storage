use v6.e.PREVIEW;
use Cro::HTTP::Response;
use WWW::GCloud;
use WWW::GCloud::Types;
use WWW::GCloud::API::Storage;
use WWW::GCloud::API::Storage::Types;

my $gcloud = WWW::GCloud.new;
my $objects = $gcloud.storage.objects;

my sub download(Promise:D $get, $into) {
    note "Downloading into '$into'";
    await $get.andthen({ .result.send-to($into, :!override) })
}

multi sub MAIN(Str:D $bucket, Str:D $object, IO::Path(Str) :$o) {
    download(
        $objects.get($bucket, $object, :media),
        $o // IO::Spec::Unix.basename($object))
}

multi sub MAIN(GCUri:D(GCSUriStr) $uri, IO::Path(Str) :$o) {
    download(
        $objects.get($uri, :media),
        $o // IO::Spec::Unix.basename($uri.path))
}
