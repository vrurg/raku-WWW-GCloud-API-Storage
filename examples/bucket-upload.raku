use v6.e.PREVIEW;

use Data::Dump;
use WWW::GCloud;
use WWW::GCloud::API::Storage;
use WWW::GCloud::R::Storage::Object;
use WWW::GCloud::API::Storage::Upload::Event;

sub MAIN( Str:D $bucket-name,
          IO:D() $file,
          # Upload as having this name
          Str :$as,
          #| Use resumable upload
          Bool:D :$resumable = False,
          #| Should we send data out in chunks or place it all in memory first?
          Bool:D :$segmented = True,
          #| Outgoing bandwidth in megabits
          UInt :$bandwidth = 100 )
{
    my $gcloud = WWW::GCloud.new;
    my $st = $gcloud.storage;
    my Int() $timeout = 60 max (1.1 * $file.s / ($bandwidth*1024*1024/8));
    my $name = $as // $file.basename;
    note "USING TIMEOUT FOR 100Mbit bandwidth: ", $timeout;
    my $uploader = $st.objects.insert(
            $bucket-name,
            $file,
            :$name,
            :$resumable,
            meta => { metadata => {
                        "user-label1" => "value 1",
                        "user-label2" => "value 2",
                    }},
            uploader => {
                :$segmented,
                :in-buffer(100*1024*1024),
                :$timeout,
            },
        );
    start react {
        whenever $uploader.progress {
            # note "GOT EVENT: ", .^name;

            when WWW::GCloud::API::Storage::Upload::Event::Done {
                with .meta {
                    note " > Done ", .name;
                }
            }

            when WWW::GCloud::API::Storage::Upload::Event::Fail {
                note " > Failed ", .meta.name, " with ", .cause.^name;
                note .cause.gist.indent(4);
            }

            when WWW::GCloud::API::Storage::Upload::Event::Retry {
                note " > Retry #", .attempt, " for ", .meta.name, " from ", (.from / (1024*1024)).fmt('%f');
            }

            when WWW::GCloud::API::Storage::Upload::Event::BufRead {
                note .meta.name, ": [", .bytes, "]", |(" offset=" ~ ($_ / (1024*1024)).fmt('%.2f') with .offset);
            }

        }

        whenever $uploader.completed {
            note "COMPLETED PROMISE resulted in ", .WHICH;
            QUIT {
                note "COMPLETED PROMISE BROKEN AS ", .WHICH;
            }
        }
    }

    note "-> started upload";
    my $meta = try await $uploader.upload;
    note "-> done uploading // ", $uploader.completed.status;
    note "Resulting meta:\n", Dump($meta, :indent(4), :skip-methods);

    note "CLEANING UP 1: ", await $st.objects.delete($bucket-name, $name);
    note "CLEANING UP 2: ", await $st.objects.delete($bucket-name, $name);
}