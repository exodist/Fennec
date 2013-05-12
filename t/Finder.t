#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Finder match => qr/\.pm$/;
use Test::More;

my $found = grep { m/FinderTest/ } @{Fennec::Finder->new->test_classes};
ok( $found, "Found test!" );

run();

my $ran = Fennec::Finder->new->collector->test_count;
die "Not all tests ran ($ran)!"
    unless $ran == 3;

1;
