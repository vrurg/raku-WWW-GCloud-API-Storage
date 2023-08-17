NAME
====

`WWW::GCloud::API::Storage` - `WWW::GCloud` implementation of [Google Storage API](https://cloud.google.com/storage/docs/json_api)

SYNOPSIS
========

```raku
use v6.e.PREVIEW;
use WWW::GCloud;
use WWW::GCloud::API::Storage;
use WWW::GCloud::R::Storage::Object;

my $gcloud = WWW::GCloud.new;
my $st = $gcloud.storage;

await $st.objects.get("bucket-name", "object-name.ext", :media)
        .andthen({ .result.send-to("output-file.ext", :!override) });
```

DESCRIPTION
===========

This module lacks complete documentation due to me not currently able to write it. Please, see some notes for [`WWW::GCloud`](https://raku.land/zef:vrurg/WWW::GCloud) framework. And look into *exmaples/* where I tried to provide meaningful code to follow.

Status
------

This module is pre-beta, pre-anything. It is incomplete and likely not well thought out at places. But it already lets you do a lot with your storages.

If there is anything you need but it is missing then, please, consider implementing it and submitting a PR. Any other approach would barely proces any outcome for what I do apologize!

Either way, this module can be used as a reference implementation for a `WWW::GGCloud` API.

Uploading
---------

Contrary to a typical convention about API resource methods returning either a [`Promise`](https://docs.raku.org/type/Promise) or a [`Supply`](https://docs.raku.org/type/Supply), when an upload is requested with `insert` method of `objects` resource an uploader object is given back to the user. The object would be implementing `WWW::GCloud::API::Storage::Upload` role.

There are two kinds of uploads are currently implemented: simple and resumable. The former is preferable for smaller files, the latter is better be used for huge ones. Where is the edge between 'small' and 'large' is determined by the bandwidth and quality of one's connection.

Either implementation of the uploader tries to optimize memory usage by reading data in chunks and submitting each chunk to the network immediately. But using `:!segemnted` flag to create the uploader object turns this behavior off for the simple uploads.

The uploader can feed data directly from a handle without knowing what lays behind the handle. The only requirement is imposed by resumable upload as it has to be able to seek within the stream in case it needs to resend a chunk.

The upload process can be monitored by subscribiting to a [`Supply`](https://docs.raku.org/type/Supply) provided by uploader's `progress` method which emits upload events like "buffer read", "retry requested", "done".

Since the actual REST calls are done by the uploader its `upload` method is the one which complies to the convention of API resource methods returning [`Promise`](https://docs.raku.org/type/Promise).

See *exmaples/bucket-upload.raku* for a reference implementation.

COPYRIGHT
=========

(c) 2023, Vadim Belman <vrurg@cpan.org>

LICENSE
=======

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.

