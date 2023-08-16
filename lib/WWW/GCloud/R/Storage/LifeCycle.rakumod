use v6.e.PREVIEW;
unit class WWW::GCloud::R::Storage::LifeCycle;

use WWW::GCloud::Record;
use WWW::GCloud::R::Storage::Billing;
use WWW::GCloud::R::Storage::IamConfiguration;
use WWW::GCloud::R::Storage::CustomPlacementConfig;

also is gc-record;

class Rule is gc-record {
    class Action is gc-record {
        has Str $.storageClass;
        has Str $.type;
    }

    class Condition is gc-record {
        has Int(Str) $.age;
        has Date(Str) $.createdBefore;
        has Bool $.isLive;
        has Int(Str) $.numNewerVersions;
        has Str:D @.matchesStorageClass;
        has Int(Str) @.daysSinceCustomTime;
        has Date(Str) $.customTimeBefore;
        has Int(Str) $.daysSinceNoncurrentTime;
        has Date(Str) $.noncurrentTimeBefore;
        has Str:D @.matchesPrefix;
        has Str:D @.matchesSuffix;
    }

    has Action $.action;
    has Condition $.condition;
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

has Rule:D @.rule;
has AutoClass $.autoclass;
has %.labels;
has RetentionPolicy $.retentionPolicy;
has WWW::GCloud::R::Storage::Billing $.billing;
has WWW::GCloud::R::Storage::IamConfiguration $.iamConfiguration;
has Str $.locationType;
has WWW::GCloud::R::Storage::CustomPlacementConfig $.customPlacementConfig;
has Str $.rpo;