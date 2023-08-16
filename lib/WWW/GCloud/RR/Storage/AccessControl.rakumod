use v6.e.PREVIEW;
unit role WWW::GCloud::RR::Storage::AccessControl;

use WWW::GCloud::RR::Storage::ProjectTeam;
use WWW::GCloud::RR::Kind;

also does WWW::GCloud::RR::Kind;

has Str $.id;
has Str $.selfLink;
has Str $.bucket;
has Str $.entity;
has Str $.role;
has Str $.email;
has Str $.domain;
has Str $.entityId;
has Str $.etag;
has WWW::GCloud::RR::Storage::ProjectTeam $.projectTeam;