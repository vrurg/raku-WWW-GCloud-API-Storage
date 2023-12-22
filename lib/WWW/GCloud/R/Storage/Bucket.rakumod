use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/json_api/v1/buckets#resource-representations
unit class WWW::GCloud::R::Storage::Bucket;

use AttrX::Mooish;
use WWW::GCloud::Record;
use WWW::GCloud::RR::Kind;
use WWW::GCloud::R::Storage::BucketAccessControl;
use WWW::GCloud::R::Storage::ObjectAccessControl;
use WWW::GCloud::R::Storage::LifeCycle;
use WWW::GCloud::R::Storage::Billing;
use WWW::GCloud::R::Storage::IamConfiguration;
use WWW::GCloud::R::Storage::CustomPlacementConfig;
use WWW::GCloud::R::Storage::Owner;

also is gc-record;
also does WWW::GCloud::RR::Kind;

class Encryption is gc-record {
    has Str $.defaultKmsKeyName;
}

class Website is gc-record {
    has Str $.mainPageSuffix;
    has Str $.notFoundPage;
}

class Logging is gc-record {
    has Str $.logBucket;
    has Str $.logObjectPrefix;
}

class CORS is gc-record {
    has Str @.origin;
    has Str @.method;
    has Str @.responseHeader;
    has Int(Str) $.maxAgeSeconds;
}

class Versioning is gc-record {
    has Bool $.enabled;
}

class AutoClass is gc-record {
    has Bool $.enabled;
    has DateTime(Str) $.toggleTime;
}

class RetentionPolicy is gc-record {
    has UInt(Str) $.retentionPeriod;
    has DateTime(Str) $.effectiveTime;
    has Bool $.isLocked;
}

has Str $.selfLink;
has Str $.id;
has Str $.name;
has UInt(Str) $.projectNumber;
has Int(Str) $.metageneration;
has Str $.location;
has Str $.storageClass;
has Str $.etag;
has Bool $.defaultEventBasedHold;
has DateTime(Str) $.timeCreated;
has DateTime(Str) $.updated;
has Encryption $.encryption;
has WWW::GCloud::R::Storage::BucketAccessControl:D @.acl;
has WWW::GCloud::R::Storage::ObjectAccessControl $.defaultObjectAcl;
has Website $.website;
has WWW::GCloud::R::Storage::Owner $.owner;
has Logging $.logging;
has CORS:D @.cors;
has Versioning $.versioning;
has WWW::GCloud::R::Storage::LifeCycle $.lifecycle;
has AutoClass $.autoclass;
has Str %.labels;
has RetentionPolicy $.retentionPolicy;
has WWW::GCloud::R::Storage::Billing $.billing;
has WWW::GCloud::R::Storage::IamConfiguration $.iamConfiguration;
has Str $.locationType;
has WWW::GCloud::R::Storage::CustomPlacementConfig $.customPlacementConfig;
has Str $.rpo;