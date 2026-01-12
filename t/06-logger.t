#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;
use Test::More tests => 5;
use File::Temp qw(tempfile);

use_ok('DupeFinder::Logger');

my $logger = DupeFinder::Logger->new(quiet => 1);
isa_ok($logger, 'DupeFinder::Logger');

$logger->info("test message");
$logger->warn("warning message");
$logger->error("error message");
pass('logging methods work');

my ($fh, $filename) = tempfile(UNLINK => 1);
close $fh;

my $file_logger = DupeFinder::Logger->new(
    file  => $filename,
    quiet => 1,
);

$file_logger->info("file log test");
undef $file_logger;

open my $read_fh, '<', $filename or die;
my $content = do { local $/; <$read_fh> };
close $read_fh;

like($content, qr/\[INFO\]/, 'file has INFO');
like($content, qr/file log test/, 'file has message');
