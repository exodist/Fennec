#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    require Fennec::Finder;
    *Fennec::Finder::validate_file = sub {
        my $self = shift;
        my ($file) = @_;
        return unless $file =~ m/\.pm$/;
        return 1;
    };
}

use Fennec::Finder;
use Test::More;

my $found = grep { m/FinderTest/ } @{Fennec::Finder->new->test_classes};
ok( $found, "Found test!" );

run();

my $ran = Fennec::Finder->new->collector->test_count;
die "Not all tests ran ($ran)!"
    unless $ran == 3;

1;
