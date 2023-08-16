use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/json_api/v1
unit class WWW::GCloud::API::Storage:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;
use WWW::GCloud;
use WWW::GCloud::API;
use WWW::GCloud::API::Storage::Buckets;
use WWW::GCloud::API::Storage::Objects;
use WWW::GCloud::Utils;

also does WWW::GCloud::API['storage'];

has $.base-url = 'https://storage.googleapis.com/storage/v1';

has WWW::GCloud::API::Storage::Buckets:D $.buckets is mooish(:lazy);
has WWW::GCloud::API::Storage::Objects:D $.objects is mooish(:lazy);

#has WWW::GCloud::API::Storage::BucketAccessControls:D $.bucket-access-controls is mooish(:lazy);

# method build-bucket-access-controls {
#     WWW::GCloud::API::Storage::BucketAccessControls.new: api => self
# }

method build-buckets {
    WWW::GCloud::API::Storage::Buckets.new: api => self
}

method build-objects {
    WWW::GCloud::API::Storage::Objects.new: api => self
}

proto method new-record(|) {*}
multi method new-record(Str:D $short-name, |c) {
    resolve-package('WWW::GCloud::R::Storage::' ~ $short-name).new(|c)
}

our sub META6 { $?DISTRIBUTION.meta }