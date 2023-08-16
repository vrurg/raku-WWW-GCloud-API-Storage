use v6.e.PREVIEW;
unit class WWW::GCloud::R::Storage::ObjectAccessControl;

use WWW::GCloud::Record;
use WWW::GCloud::RR::Storage::AccessControl;

also does WWW::GCloud::Record;
also does WWW::GCloud::RR::Storage::AccessControl;

has Str $.object;