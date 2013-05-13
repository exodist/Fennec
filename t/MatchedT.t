#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
use Fennec::Runner qw/FinderTest/;
use Test::More;

my $found = grep { m/FinderTest/ } @{Fennec::Runner->new->loaded_classes};
ok( $found, "Found test!" );

run();

my $ran = Fennec::Runner->new->collector->test_count;
die "Not all tests ran ($ran)!"
    unless $ran == 3;

1;
