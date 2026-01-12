#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;
use Test::More tests => 12;
use File::Temp qw(tempfile);

use_ok('DupeFinder::Hasher');

my $hasher = DupeFinder::Hasher->new();
isa_ok($hasher, 'DupeFinder::Hasher');
is($hasher->algorithm, 'SHA256', 'default algorithm');

my @algos = DupeFinder::Hasher->supported_algorithms();
ok(scalar @algos >= 4, 'has algorithms');
ok(grep({ $_ eq 'SHA256' } @algos), 'includes SHA256');

my ($fh, $filename) = tempfile(UNLINK => 1);
print $fh "test content\n";
close $fh;

my $hash1 = $hasher->hash_file($filename);
ok($hash1, 'got hash');
like($hash1, qr/^[a-f0-9]{64}$/i, 'valid SHA256 hex');

my $hash2 = $hasher->hash_file($filename);
is($hash1, $hash2, 'consistent hash');

my $md5_hasher = DupeFinder::Hasher->new(algorithm => 'MD5');
my $md5_hash = $md5_hasher->hash_file($filename);
like($md5_hash, qr/^[a-f0-9]{32}$/i, 'valid MD5 hex');
isnt($hash1, $md5_hash, 'different algorithms');

is($hasher->hash_file('/nonexistent/file'), undef, 'missing file');

my $quick = $hasher->quick_hash($filename);
ok($quick, 'quick hash works');
