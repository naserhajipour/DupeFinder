#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;
use Test::More tests => 10;
use File::Temp qw(tempfile);

use_ok('DupeFinder::Config');

my $cfg = DupeFinder::Config->new();
isa_ok($cfg, 'DupeFinder::Config');

is($cfg->get('hash', 'algorithm'), 'SHA256', 'default algorithm');
is($cfg->get('scan', 'min_size'), 1, 'default min_size');
is($cfg->get('output', 'format'), 'text', 'default format');

$cfg->set('MD5', 'hash', 'algorithm');
is($cfg->get('hash', 'algorithm'), 'MD5', 'set value');

my ($fh, $filename) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
print $fh <<'YAML';
hash:
  algorithm: SHA512
scan:
  min_size: 1024
YAML
close $fh;

my $cfg2 = DupeFinder::Config->new(config_file => $filename);
is($cfg2->get('hash', 'algorithm'), 'SHA512', 'loaded algorithm');
is($cfg2->get('scan', 'min_size'), 1024, 'loaded min_size');
is($cfg2->get('output', 'format'), 'text', 'preserved default');

my $all = $cfg2->all();
is(ref($all), 'HASH', 'all returns hash');
