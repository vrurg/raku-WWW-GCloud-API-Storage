use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/json_api/v1#buckets
unit class WWW::GCloud::API::Storage::Buckets;

use WWW::GCloud::X;
use WWW::GCloud::R::Storage::Buckets;
use WWW::GCloud::API::Storage::Types;
use WWW::GCloud::Resource;
use WWW::GCloud::QueryParams;

also does WWW::GCloud::Resource;
also does WWW::GCloud::QueryParams;

# https://cloud.google.com/storage/docs/json_api/v1/buckets/list
method list(::?CLASS:D: Str:D $project, Bool :$paginate, *%args)
    is gc-params( query => %( :STD-PARAMS, :maxResults(UInt), :prefix(Str), :projection(GCBProjection) ) )
{
    self.gc-validate-args: |%args, -> :%query {
        %query.append: (:$project, :!prettyPrint);
        $.api.paginate: "get", "b", as => WWW::GCloud::R::Storage::Buckets, :%query, :$paginate
    }
}

# https://cloud.google.com/storage/docs/json_api/v1/buckets/get
method get(::?CLASS:D: Str:D $bucket, *%args)
    is gc-params( :query( :STD-PARAMS, :projection(GCBProjection) ))
{
    self.gc-validate-args: |%args, -> :%query {
        $.api.get: "b/$bucket", as => WWW::GCloud::R::Storage::Bucket, :%query
    }
}

# https://cloud.google.com/storage/docs/json_api/v1/buckets/insert
method insert(::?CLASS:D: Str:D $project, WWW::GCloud::R::Storage::Bucket:D $bucket, *%args)
    is gc-params( :query( :STD-PARAMS, :predefinedAcl(Str),
                  :predefinedDefaultObjectAcl(Str), :projection(GCBProjection) ) )
{
    self.gc-validate-args: |%args, -> :%query {
        %query<project> = $project;
        $.api.post: "b", $bucket, :%query, :as(WWW::GCloud::R::Storage::Bucket)
    }
}

# https://cloud.google.com/storage/docs/json_api/v1/buckets/delete

method delete(::?CLASS:D: Str:D $bucket, *%args)
    is gc-params( :query( :STD-PARAMS, :ifMetagenerationMatch(Int), :ifMetagenerationNotMatch(Int) ) )
{
    self.gc-validate-args: |%args, -> :%query {
        $.api.delete( "b/" ~ $bucket, :%query ).andthen({ True })
    }
}