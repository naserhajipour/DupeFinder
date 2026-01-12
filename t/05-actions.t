#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;
use Test::More tests => 8;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('DupeFinder::Actions');

my $actions = DupeFinder::Actions->new(dry_run => 1);
isa_ok($actions, 'DupeFinder::Actions');

my $dir = tempdir(CLEANUP => 1);
my @files;
for my $i (1..3) {
    my $path = File::Spec->catfile($dir, "file$i.txt");
    open my $fh, '>', $path or die;
    print $fh "content\n";
    close $fh;
    push @files, $path;
}

my $dupes = { 'hash123' => \@files };

my $deleted = $actions->delete_duplicates($dupes, 'first');
is(scalar @$deleted, 2, 'dry run delete count');
ok(-f $files[0], 'file1 exists (dry run)');
ok(-f $files[1], 'file2 exists (dry run)');

my $log = $actions->get_log();
ok(scalar @$log > 0, 'has log entries');
like($log->[0], qr/DELETE/, 'log has DELETE');

$actions->clear_log();
is(scalar @{$actions->get_log()}, 0, 'log cleared');
