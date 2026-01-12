#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;
use Test::More tests => 11;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('DupeFinder::Scanner');

my $dir = tempdir(CLEANUP => 1);

for my $name (qw(file1.txt file2.txt file3.txt)) {
    my $path = File::Spec->catfile($dir, $name);
    open my $fh, '>', $path or die;
    print $fh "duplicate content\n";
    close $fh;
}

my $unique = File::Spec->catfile($dir, 'unique.txt');
open my $fh, '>', $unique or die;
print $fh "unique content here\n";
close $fh;

my $scanner = DupeFinder::Scanner->new();
isa_ok($scanner, 'DupeFinder::Scanner');

my $stats = $scanner->scan($dir);
is(ref($stats), 'HASH', 'stats is hash');
is($stats->{scanned}, 4, 'scanned 4 files');
ok($stats->{total_size} > 0, 'has total size');

my $files = $scanner->files();
is(scalar @$files, 4, 'files array');

my $dupes = $scanner->find_duplicates();
is(ref($dupes), 'HASH', 'duplicates is hash');
is(scalar keys %$dupes, 1, 'one duplicate group');

my ($hash) = keys %$dupes;
is(scalar @{$dupes->{$hash}}, 3, 'three duplicates');

my $dup_stats = $scanner->get_duplicate_stats();
is($dup_stats->{groups}, 1, 'one group');
is($dup_stats->{total_files}, 3, 'three total dupes');
