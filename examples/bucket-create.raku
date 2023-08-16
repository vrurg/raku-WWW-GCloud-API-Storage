use v6.e.PREVIEW;

use WWW::GCloud;
use WWW::GCloud::API::Storage;
use WWW::GCloud::R::Storage::Bucket;
use Data::Dump;

sub MAIN(Str:D $project-id, Str:D $bucket, Bool :$create, Bool :$delete) {
    my $gcloud = WWW::GCloud.new;
    my $st = $gcloud.storage;

    if $create {
        my $meta = $st.new-record:
                    "Bucket",
                    :name($bucket),
                    labels => {
                        :createdby("bucket-create"),
                        :purpose("demo-only"),
                    },
                    ;
        my $bmeta = await $st.buckets.insert($project-id, $meta);
        say Dump( $bmeta,
                  :skip-methods,
                  :no-postfix,
                  overrides => %(
                    DateTime => sub ($d) { $d.gist }
                  ));
    }

    if $create && $delete {
        unless prompt("Both --create and --delete are used. So, delete right now? ") ~~ /:i ^ yes | y $/ {
            $delete = False;
        }
    }

    if $delete {
        my $result = await $st.buckets.delete($bucket)
                            .orelse({
                                note "Error while deleting:\n", .gist.indent(4);
                                False
                            });
        say "Delete of '$bucket' ", $result ?? "succeed" !! "failed";
    }
}