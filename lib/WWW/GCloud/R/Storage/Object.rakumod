use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/json_api/v1/objects#resource-representations
unit class WWW::GCloud::R::Storage::Object;

use MIME::Base64;
use Method::Also;
use WWW::GCloud::Record;
use WWW::GCloud::Types;
use WWW::GCloud::RR::Kind;
use WWW::GCloud::R::Storage::ObjectAccessControl;
use WWW::GCloud::R::Storage::CustomerEncryption;
use WWW::GCloud::R::Storage::Owner;

also is gc-record;
also does WWW::GCloud::RR::Kind;

submethod TWEAK(Blob :$md5, Blob :$crc32) {
    with $md5 {
        $!md5Hash //= MIME::Base64.encode($md5);
    }
    with $crc32 {
        $!crc32c //= MIME::Base64.encode($crc32);
    }
}

has Str $.id;
has Str $.name;
has Str $.bucket;
has Str $.selfLink;
has Str $.mediaLink;
has Int(Str) $.generation;
has Int(Str) $.metageneration;
has Str $.contentType;
has Str $.storageClass;
has UInt(Str) $.size;
has Str $.md5Hash;
has Str $.contentEncoding;
has Str $.contentDisposition;
has Str $.contentLanguage;
has Str $.cacheControl;
has Str $.crc32c;
has Int $.componentCount;
has Str $.etag;
has Str $.kmsKeyName;
has Bool $.temporaryHold;
has Bool $.eventBasedHold;
has DateTime(Str) $.retentionExpirationTime;
has DateTime(Str) $.timeCreated;
has DateTime(Str) $.updated;
has DateTime(Str) $.timeDeleted;
has DateTime(Str) $.timeStorageClassUpdated;
has DateTime(Str) $.customTime;
has %.metadata;
has WWW::GCloud::R::Storage::ObjectAccessControl $.acl;
has WWW::GCloud::R::Storage::Owner $.owner;
has WWW::GCloud::R::Storage::CustomerEncryption $.customerEncryption;

method GCUri {
    GCUri.parse: self.uri
}

method Str is also<uri URI> { 'gs://' ~ $.bucket ~ '/' ~ $.name }

method md5 {
    MIME::Base64.decode($.md5Hash)
}

method crc32 {
    MIME::Base64.decode($.crc32c)
}

method md5-hex {
    MIME::Base64.decode($.md5Hash).map(*.fmt('%02x')).join
}

method crc32c-hex {
    MIME::Base64.decode($.crc32c).map(*.fmt('%02x')).join
}