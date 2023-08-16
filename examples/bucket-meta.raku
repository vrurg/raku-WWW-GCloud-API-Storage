use v6.e.PREVIEW;

use WWW::GCloud;
use WWW::GCloud::API::Storage;
use Data::Dump;
use Base64::Native;
use OpenSSL::Digest::MD5;

sub MAIN(Str:D $bucket-name) {
    my $gcloud = WWW::GCloud.new;
    my $st = $gcloud.storage;
    $st.buckets.get($bucket-name);
    # say Dump( await($st.buckets.get($bucket-name)),
    #           :skip-methods,
    #           :no-postfix,
    #           overrides => {
    #             DateTime => sub ($d) { $d.gist }
    #           }
    #         );

    my $for-download;
    for $st.objects.list($bucket-name).list -> $b {
        $for-download //= $b;
        say $b;
        say " - ", base64-decode($b.md5Hash).list.map(*.fmt('%02x')).join;
    }

    my $dest = $*PROGRAM.parent(1).add($for-download.name);
    my $resp = await($st.objects.get($for-download.bucket, $for-download.name, :alt<media>));
    say "Receiving ", $for-download.name, ", ", $resp.length, " from ", $for-download.bucket, " into ", ~$dest;
    react whenever $resp.send-to($dest, :close, :overwrite) -> $ev {
        note ": ", $ev.total-received, " / ", $ev.total-sent;
    }

    my $md5 = OpenSSL::Digest::MD5.new;
    $md5.addfile(~$dest);
    say "Received MD5: ", $md5.hex;
}