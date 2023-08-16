use v6.e.PREVIEW;
unit class WWW::GCloud::RR::Storage::ProjectTeam;

use WWW::GCloud::Record;

also does WWW::GCloud::Record;

has Str $.projectNumber is kebabish;
has Str $.team;