use v6.e.PREVIEW;
use WWW::GCloud;
use WWW::GCloud::Types;
use WWW::GCloud::API::Storage;
use WWW::GCloud::API::Storage::Types;
use Data::Dump;

my $gcloud = WWW::GCloud.new;
my $objects = $gcloud.storage.objects;

sub dump($obj) {
    say Dump( $obj,
                :skip-methods,
                :no-postfix,
                overrides => %(
                    DateTime => sub ($d) { $d.gist }));
}

multi sub MAIN(Str:D $bucket, Str:D $object, Bool :$folder) {
    dump await ( $folder
        ?? $objects.get($bucket, :folder($object))
        !! $objects.get($bucket, $object, :!media)
    )
}

multi sub MAIN(GCSUriStr $uri, Bool :$folder) {
    dump await ($folder
        ?? $objects.get(:folder($uri))
        !! $objects.get($uri))
}