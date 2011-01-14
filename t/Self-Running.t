#!/usr/bin/perl
package Fennec::Test::SelfRunning;
use strict;
use warnings;

use Test::More;
use Fennec;
use TAP::Parser;

can_ok( __PACKAGE__, 'tests' );

tests is_in_runner => sub {
    my $self = shift;
    ok( 1 );
    ok( 1, "A" );
    ok( 1, "b" );
    ok( 1, "c" );
    ok( 0, "blah" );
    ok( 0, "blah2" );
    {
        local $TODO = "uhg";
        is( 1, 2, "hup" );
    }
};

1;
