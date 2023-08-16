use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/json_api/v1/buckets/list#response
unit class WWW::GCloud::R::Storage::Buckets;

use WWW::GCloud::Record;
use WWW::GCloud::RR::Kind;
use WWW::GCloud::R::Storage::Bucket;
use WWW::GCloud::RR::Paginatable;

also is gc-record( :paginating(WWW::GCloud::R::Storage::Bucket, "buckets", :json-name<items>) );
also does WWW::GCloud::RR::Kind;