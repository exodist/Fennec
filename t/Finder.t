#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Finder;
use Test::More;

is( $FinderTest::LOADED, 1, "Found and loaded test automatically" );

run();
