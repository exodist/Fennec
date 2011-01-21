#!/usr/bin/perl
package TestClass::Test;
use strict;
use warnings;

use Fennec skip_without => [qw/ Test::Class /],
           base => 'Test::Class';

isa_ok( __PACKAGE__, 'Test::Class' );

sub test_basic : Test(1) {
    ok( 1, "Test::Class - test" );
}

tests foo => sub { ok( 1, 'bar' )};

1;
