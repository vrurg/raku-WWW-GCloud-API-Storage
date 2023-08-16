use v6.e.PREVIEW;
unit class WWW::GCloud::R::Storage::CustomerEncryption;

use WWW::GCloud::Record;

also is gc-record;

has Str $.encryptionAlgorithm;
has Str $.keySha256;