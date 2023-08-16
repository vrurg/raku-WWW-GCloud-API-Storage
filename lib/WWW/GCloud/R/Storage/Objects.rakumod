use v6.e.PREVIEW;
unit class WWW::GCloud::R::Storage::Objects;

use WWW::GCloud::Record;
use WWW::GCloud::RR::Paginatable;
use WWW::GCloud::RR::Kind;
use WWW::GCloud::R::Storage::Object;

also is gc-record;
also does WWW::GCloud::RR::Kind;
also does WWW::GCloud::RR::Paginatable[WWW::GCloud::R::Storage::Object];

has Str:D @.prefixes;
