use v6.e.PREVIEW;
unit module WWW::GCloud::API::Storage::X;

use WWW::GCloud::X;
use WWW::GCloud::Types;
use Cro::HTTP::Client;

class ResumableStatusCode is X::Cro::HTTP::Error does WWW::GCloud::X::Base {
    has $.meta;
    method message {
        "Status of a resumable download can't determined: unknown status code " ~ $.response.status
    }
}

class OutOfAttempts does WWW::GCloud::X::Core {
    has @.failures;
    has $.meta;
    method message {
        "Cannot finish a resumable upload"
            ~ (" of '" ~  $_ ~ "'" with ($.meta andthen $.meta.name))
            ~ ": no attempts left"
    }
}

class SizeMismatch does WWW::GCloud::X::Core {
    has Str $.name;
    has Int:D $.expected is required;
    has Int:D $.got is required;
    has Str:D $.where is required;

    method message {
        "Meta " ~ ($.name ?? "for $.name " !! "")
            ~ "declares object size " ~ $.expected
            ~ " bu only " ~ $.got ~ " available in " ~ $.where
    }
}

class NonGCSUri does WWW::GCloud::X::Core {
    has Str:D(GCUri) $.uri is required;
    has Str $.when;
    method message {
        "Not a Google Storage URI '" ~ $.uri ~ "'" ~ ($.when ?? " " ~ $.when !! "")
    }
}