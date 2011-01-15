#!/usr/bin/perl
package TestClass::Test;
use strict;
use warnings;

use Fennec skip_without => [qw/ Test::Class /],
           base => 'Test::Class';

sub test_basic : Test(1) {
    ok( 1, "Test::Class - test" );
}

1;
