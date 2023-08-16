use v6.e.PREVIEW;
use Cro::HTTP::Response;
use WWW::GCloud::Utils;
use WWW::GCloud::Record;

class WWW::GCloud::API::Storage::Upload::Event {

    has Cro::HTTP::Response $.response;

    multi method new(Str:D $short-name, |c) is raw {
        my $cstash := ::?CLASS.WHO;
        ( $cstash.EXISTS-KEY($short-name)
            ?? $cstash.AT-KEY($short-name)
            !! resolve-package(::?CLASS.^name ~ "::" ~ $short-name) ).new(|c)
    }
}

our role WWW::GCloud::API::Storage::Upload::Event::Meta {
    has WWW::GCloud::Record $.meta;
}

class WWW::GCloud::API::Storage::Upload::Event::Done
    is WWW::GCloud::API::Storage::Upload::Event
    does WWW::GCloud::API::Storage::Upload::Event::Meta
{}

class WWW::GCloud::API::Storage::Upload::Event::Fail
    is WWW::GCloud::API::Storage::Upload::Event
    does WWW::GCloud::API::Storage::Upload::Event::Meta
{
    has Exception:D $.cause is required;
}

class WWW::GCloud::API::Storage::Upload::Event::Retry
    is WWW::GCloud::API::Storage::Upload::Event
    does WWW::GCloud::API::Storage::Upload::Event::Meta
{
    has UInt:D $.attempt is required;
    has Int:D $.from is required;
}

class WWW::GCloud::API::Storage::Upload::Event::BufRead
    is WWW::GCloud::API::Storage::Upload::Event
    does WWW::GCloud::API::Storage::Upload::Event::Meta
{
    has UInt:D $.bytes is required;
    has UInt $.offset;
    has UInt $.from;
}