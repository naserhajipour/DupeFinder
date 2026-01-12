#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;
use Test::More tests => 8;

use_ok('DupeFinder::Reporter');

my $reporter = DupeFinder::Reporter->new(color => 0);
isa_ok($reporter, 'DupeFinder::Reporter');

my $dupes = {
    'abc123' => ['/path/to/file1.txt', '/path/to/file2.txt'],
};
my $stats = { scanned => 10, total_size => 1024 };

my $text = $reporter->report($dupes, $stats);
ok($text, 'text report generated');
like($text, qr/Duplicate/, 'contains Duplicate');
like($text, qr/file1\.txt/, 'contains filename');

my $json_reporter = DupeFinder::Reporter->new(format => 'json');
my $json = $json_reporter->report($dupes, $stats);
like($json, qr/"duplicates"/, 'valid json structure');

my $csv_reporter = DupeFinder::Reporter->new(format => 'csv');
my $csv = $csv_reporter->report($dupes, $stats);
like($csv, qr/hash,size,path/, 'csv header');
like($csv, qr/abc123/, 'csv contains hash');
