
use v6.e.PREVIEW;
# https://cloud.google.com/storage/docs/json_api/v1#objects
unit class WWW::GCloud::API::Storage::Objects;

use experimental :will-complain;

use Cro::Uri :encode-percents;
use MIME::Types;
use WWW::GCloud::API::Storage::Types;
use WWW::GCloud::API::Storage::Upload::Resumable;
use WWW::GCloud::API::Storage::Upload::Simple;
use WWW::GCloud::QueryParams;
use WWW::GCloud::R::Storage::Objects;
use WWW::GCloud::Resource;
use WWW::GCloud::Types;
use WWW::GCloud::Utils;

also does WWW::GCloud::Resource;
also does WWW::GCloud::QueryParams;

my sub to-rel(Str:D $path) {
    $path.chars < 2 ?? $path !! GCSUri.object-name($path)
}

my sub folderize(Str:D $folder) {
    to-rel($folder) andthen ($_ ~ (.ends-with("/") ?? "" !! "/"))
}

method !mime-type(IO:D() $file) {
    mime-type($file) // 'application/octet-stream'
}

# https://cloud.google.com/storage/docs/json_api/v1/objects/list
method list( ::CLASS:D: Str:D $bucket, Str $matchGlob?, *%args )
    is gc-params(
        :query( :STD-PARAMS, :delimiter(Str), :endOffset(Str), :includeTrailingDelimiter(Bool),
                :maxResults(Int), :prefix(Str), :projection(Str), :startOffset(Str), :versions(Bool) ))
{
    self.gc-validate-args: |%args, -> :%query {
        %query<matchGlob> = $_ with $matchGlob;
        $.api.paginate: "get", 'b/' ~ $bucket ~ '/o', :as(WWW::GCloud::R::Storage::Objects), :%query
    }
}

# https://cloud.google.com/storage/docs/json_api/v1/objects/get
proto method get(|) {*}
multi method get( ::?CLASS:D: Str:D $bucket, Str:D $object, Bool :$media, *%args )
    is gc-params(
        :query( :STD-PARAMS, :generation(Int), :ifGenerationMatch(Int(Bool)),
                :ifGenerationNotMatch(Int(Bool)), :ifMetagenerationMatch(Int(Bool)),
                :ifMetagenerationNotMatch(Int(Bool)), :projection(GCBProjection) ),
        :header( :STD-PARAMS<x-encryption-algorithm x-encryption-key x-encryption-key-sha256> ))
{
    self.gc-validate-args: |%args, -> :%query, :@headers {
        my $api-path = IO::Spec::Unix.canonpath( 'b/' ~ $bucket ~ '/o/' ~ encode-percents($object) );

        with $media {
            %query<alt> = $_ ?? 'media' !! 'json';
        }

        # The response body is going to be a file body which is unlikely a JSON
        if $media || (%query<alt> andthen $_ eq 'media') {
            return $.api.get: $api-path, :%query, :@headers, :!json-body
        }

        $.api.get: $api-path, :as(WWW::GCloud::R::Storage::Object), :%query, :@headers
    }
}
multi method get( ::?CLASS:D: GCSUri:D(GCSUriStr) $uri, *%args) {
    if $uri.path.ends-with("/") {
        self.get: :folder($uri), |%args
    }
    else {
        self.get: $uri.authority, to-rel($uri.path), |%args
    }
}
# Candidates with :folder argument allow folder paths without the ending /
multi method get( ::?CLASS:D: Str:D $bucket, Str:D :$folder, *%args)
    is gc-params(
        :query( :STD-PARAMS, :generation(Int), :ifGenerationMatch(Int(Bool)),
                :ifGenerationNotMatch(Int(Bool)), :ifMetagenerationMatch(Int(Bool)),
                :ifMetagenerationNotMatch(Int(Bool)), :projection(GCBProjection) ) )
{
    self.gc-validate-args: |%args, -> :%query, {
        %query<alt> = 'json';
        my $api-path = 'b/' ~ $bucket ~ '/o/' ~ encode-percents( folderize($folder) );
        $.api.get: $api-path, :%query, :as(WWW::GCloud::R::Storage::Object)
    }
}
multi method get( ::?CLASS:D: GCSUri:D(GCSUriStr) :folder($uri), *%args)
    is gc-params(
        :query( :STD-PARAMS, :generation(Int), :ifGenerationMatch(Int(Bool)),
                :ifGenerationNotMatch(Int(Bool)), :ifMetagenerationMatch(Int(Bool)),
                :ifMetagenerationNotMatch(Int(Bool)), :projection(GCBProjection) ) )
{
    self.gc-validate-args: |%args, -> :%query, {
        %query<alt> = 'json';
        my $bucket = $uri.authority;
        my $folder = $uri.path || "/";
        my $api-path = 'b/' ~ $bucket ~ '/o/' ~ encode-percents( folderize($folder) );
        $.api.get: $api-path, :%query, :as(WWW::GCloud::R::Storage::Object)
    }
}

# https://cloud.google.com/storage/docs/json_api/v1/objects/insert
# and https://cloud.google.com/storage/docs/performing-resumable-uploads because this method is used by default
my subset MetaObject of Any
    will complain { "expected either a storage object or a hash of keys, got " ~ .gist }
    where Any:U | WWW::GCloud::R::Storage::Object | Hash:D | Nil;

method !maybe-new-meta(MetaObject $meta, %query, Bool :$override, *%overrides) is raw {
    my $is-object = $meta ~~ WWW::GCloud::R::Storage::Object:D;
    return $meta if $is-object && !$override;
    my %meta-profile;
    if $meta ~~ Hash:D {
        %meta-profile = $meta;
    }
    elsif $is-object {
        %meta-profile<name> = $meta.name;
    }
    %meta-profile<name> //= %overrides<name> // %query<name> // self.die("File name is not specified in call to 'insert'");
    $is-object
        ?? $meta.clone: |%meta-profile, |%overrides
        !! WWW::GCloud::R::Storage::Object.new: |%meta-profile, |%overrides;
}

method !url-for-bucket(Str:D $bucket) {
    'https://' ~ $.api.api-url.host ~ '/upload/storage/v1/b/' ~ $bucket ~ '/o';
}

proto method insert(|) {*}

multi method insert(::?CLASS:D: GCSUri:D(GCSUriStr) $dest, |c) {
    if $dest.is-folder {
        return self.insert: folder => $dest, |c
    }
    self.insert: $dest.bucket, :name($dest.object-name), |c
}

multi method insert(::?CLASS:D: Str:D $bucket, IO::Path:D(Str:D) $path, *%c) {
    self.insert: $bucket, $path.open(:r, :bin), :size($path.s), :name($path.basename), :$path, |%c
}

multi method insert( ::?CLASS:D:
                     Str:D $bucket,
                     IO::Handle:D $source-handle,
                     MetaObject :$meta is copy = Nil,
                     UInt:D :length(:$size),
                     Bool :$resumable,
                     IO::Path :$path,
                     # Uploader parameters
                     :%uploader,
                     *%args )
    is gc-params(
        query => ( :STD-PARAMS, :contentEncoding(Str), :ifGenerationMatch(Int), :ifGenerationNotMatch(Int), :name(Str),
                   :ifMetagenerationMatch(Int), :kmsKeyName(Str), :predefinedAcl(Str), :projection(GCBProjection) ),
        headers => ( :STD-PARAMS<x-encryption-algorithm x-encryption-key x-encryption-key-sha256> ))
{
    self.gc-validate-args: |%args, -> :%query, :@headers {
        $meta = self!maybe-new-meta($meta, %query, content-type => self!mime-type(~$path), :$size);

        # When creating an uploader intance we don't allow the user to override our parameters like :%query, :$url, etc.
        $.api.create: ($resumable
                            ?? WWW::GCloud::API::Storage::Upload::Resumable
                            !! WWW::GCloud::API::Storage::Upload::Simple),
                        |%uploader, :%query, :@headers, :$meta, :$path,
                        :handle($source-handle), url => self!url-for-bucket($bucket)
    }
}

multi method insert( ::?CLASS:D: Str:D $bucket, Str:D :$folder, MetaObject :$meta is copy = Nil, *%args )
    is gc-params(
        query => ( :STD-PARAMS, :ifGenerationMatch(Int), :ifGenerationNotMatch(Int), :name(Str),
                   :ifMetagenerationMatch(Int), :kmsKeyName(Str), :predefinedAcl(Str), :projection(GCBProjection) ) )
{
    self.gc-validate-args: |%args, -> :%query {
        my $name = folderize($folder);
        $meta = self!maybe-new-meta($meta, %query, content-type => 'text/plain', size => 0, :$name, :override);
        $.api.create( WWW::GCloud::API::Storage::Upload::Simple,
                      :%query, :$meta, :body(''), url => self!url-for-bucket($bucket) )
            .upload(as => WWW::GCloud::R::Storage::Object)
    }
}

multi method insert( ::?CLASS:D: GCSUri:D(GCSUriStr) :folder($gs-uri), MetaObject :$meta is copy = Nil, *%args )
    is gc-params(
        query => ( :STD-PARAMS, :ifGenerationMatch(Int), :ifGenerationNotMatch(Int), :name(Str),
                   :ifMetagenerationMatch(Int), :kmsKeyName(Str), :predefinedAcl(Str), :projection(GCBProjection) ) )
{
    # gs://bucket/folder/path
    self.insert: $gs-uri.bucket, folder => folderize($gs-uri.object), :$meta, |%args
}

proto method delete(|) {*}
multi method delete(::?CLASS:D: Str:D $bucket, Str:D $object, *%args)
    is gc-params(
        query => ( :STD-PARAMS, :generation(Int), :ifGenerationMatch(Int), :ifGenerationNotMatch(Int),
                   :ifMetagenerationMatch(Int), :ifMetagenerationNotMatch(Int) ) )
{
    self.gc-validate-args: |%args, -> :%query {
        $.api.delete( 'b/' ~ $bucket ~ '/o/' ~ encode-percents($object), :%query ).andthen({ True })
    }
}
multi method delete(::?CLASS:D: GCSUri:D(GCSUriStr) $gcs-uri, *%args)
    is gc-params(
        query => ( :STD-PARAMS, :generation(Int), :ifGenerationMatch(Int), :ifGenerationNotMatch(Int),
                   :ifMetagenerationMatch(Int), :ifMetagenerationNotMatch(Int) ) )
{
    self.gc-validate-args: |%args, -> :%query {
        $.api
            .delete( 'b/' ~ $gcs-uri.authority ~ '/o/' ~ encode-percents(to-rel($gcs-uri.path)), :%query )
            .andthen({ True })
    }
}
multi method delete(::?CLASS:D: Str:D $bucket, Str:D :$folder, *%args)
    is gc-params(
        query => ( :STD-PARAMS, :generation(Int), :ifGenerationMatch(Int), :ifGenerationNotMatch(Int),
                   :ifMetagenerationMatch(Int), :ifMetagenerationNotMatch(Int) ) )
{
    self.gc-validate-args: |%args, -> :%query {
        $.api.delete( 'b/' ~ $bucket ~ '/o/' ~ encode-percents( folderize($folder) ), :%query ).andthen({
            True
            })
    }
}

proto method exists(|) {*}
multi method exists(::?CLASS:D: Str:D $bucket, Str:D :$folder!, *%args)
    is gc-params(
        :query( :STD-PARAMS, :delimiter(Str), :includeTrailingDelimiter(Bool), :projection(Str), :versions(Bool) ))
{
    self.gc-validate-args: |%args, -> :%query {
        %query<maxResults> = 1;
        %query<prefix> = folderize($folder);
        $.api.get('b/' ~ $bucket ~ '/o' , :as(WWW::GCloud::R::Storage::Objects), :%query)
            .andthen({ ? .result.items })
    }
}
multi method exists(::?CLASS:D: GCSUri:D(GCSUriStr) :folder($gs-uri)!, *%args) {
    # gs://bucket/folder/path
    self.exists: $gs-uri.bucket, folder => $gs-uri.object, |%args
}
multi method exists(::?CLASS:D: Str:D $bucket, Str:D $matchGlob, *%args)
    is gc-params(
        :query( :STD-PARAMS, :delimiter(Str), :includeTrailingDelimiter(Bool), :projection(Str), :versions(Bool) ))
{
    self.gc-validate-args: |%args, -> :%query {
        %query<maxResults> = 1;
        %query<matchGlob> = $_ with $matchGlob;
        $.api.get('b/' ~ $bucket ~ '/o' , :as(WWW::GCloud::R::Storage::Objects), :%query)
            .andthen({ ? .result.items })
    }
}
multi method exists(::?CLASS:D: GCSUri:D(GCSUriStr) $gs-uri, *%args) {
    self.exists: $gs-uri.bucket, $gs-uri.object, |%args
}