use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/json_api/v1/buckets#resource-representations
unit class WWW::GCloud::R::Storage::IamConfiguration;

use WWW::GCloud::Record;

also is gc-record;

class UniformBucketLevelAccess is gc-record {
    has Bool $.enabled;
    has DateTime(Str) $.lockedTime;
}

enum GCIAMCPubAccessPrevention is export(:types) (GCIAMC_INHERITED => "inherited", GCIAMC_ENFORCED => "enforced");

has GCIAMCPubAccessPrevention(Str) $.publicAccessPrevention;
has UniformBucketLevelAccess $.uniformBucketLevelAccess;
has UniformBucketLevelAccess $.bucketPolicyOnly;

