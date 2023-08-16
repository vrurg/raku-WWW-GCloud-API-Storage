use v6.e.PREVIEW;
use WWW::GCloud;
use WWW::GCloud::API::Storage;
use Data::Dump;

sub MAIN(Str:D $bucket, Str:D $folder, Bool :$create, Bool :$delete, Bool :$exists, Bool :$get) {
    my $gcloud = WWW::GCloud.new;
    my $st = $gcloud.storage;
    my $objects = $st.objects;

    my sub dump($obj) {
        say Dump( $obj,
                  :skip-methods,
                  :no-postfix,
                  overrides => %(
                      DateTime => sub ($d) { $d.gist }));
    }

    if $exists {
        await $objects.exists($bucket, :$folder).andthen({ say "Folder '$folder' " ~ (.result ?? "" !! "doesn't ") ~ "exists" })
    }

    if $create {
        await $objects.insert($bucket, :$folder, meta => %( metadata => %( :label1<foo1>, :bar<foo2> ) ))
                .andthen({
                    dump(.result);
                    say "Folder '$folder' created.";
                });
        # my $object = await $objects.get($bucket, $folder, :media);
    }

    if $delete {
        await $objects.delete($bucket, :$folder)
                .andthen({
                    say "Folder '$folder' deleted.";
                })
                .orelse({
                    my $ex = .cause;
                    note $ex.response.request;
                    $ex.rethrow;
                })
    }
}