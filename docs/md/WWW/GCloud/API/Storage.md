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

COPYRIGHT
=========

(c) 2023, Vadim Belman <vrurg@cpan.org>

LICENSE
=======

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.

