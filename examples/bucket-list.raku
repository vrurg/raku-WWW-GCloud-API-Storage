use v6.e.PREVIEW;

use WWW::GCloud;
use WWW::GCloud::API::Storage;
use Data::Dump;

sub MAIN(Str:D $project-id) {
    my $gcloud = WWW::GCloud.new;
    my $st = $gcloud.storage;
    for $st.buckets.list($project-id).list {
        say Dump( $_,
                  :skip-methods,
                  :no-postfix,
                  overrides => %(
                    DateTime => sub ($d) { $d.gist }
                  )
                  );
    }
}