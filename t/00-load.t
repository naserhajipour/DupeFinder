#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;
use Test::More tests => 7;

use_ok('DupeFinder::Config');
use_ok('DupeFinder::Hasher');
use_ok('DupeFinder::Scanner');
use_ok('DupeFinder::Reporter');
use_ok('DupeFinder::Actions');
use_ok('DupeFinder::Logger');
use_ok('DupeFinder::CLI');

diag("DupeFinder v$DupeFinder::CLI::VERSION");
