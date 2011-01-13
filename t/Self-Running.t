#!/usr/bin/perl
package Fennec::Test::SelfRunning;
use strict;
use warnings;

use Test::More;
use Fennec;

tests is_in_runner => sub {
    my $self = shift;
    ok( 1 );
    ok( 0, "blah" );
    is( 1, 2, "hup" );
};

1;
