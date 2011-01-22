#!/usr/bin/perl
package Fennec::Test::SelfRunning;
use strict;
use warnings;

use Fennec parallel => 2;

describe blah => sub {
    tests group_a => sub { ok( 1, 'a' )};
    tests group_b => sub { ok( 1, 'b' )};
    tests group_c => sub { ok( 1, 'c' )};
    tests group_d => sub { ok( 1, 'd' )};
    tests group_e => sub { ok( 1, 'e' )};
    describe foo => sub {
        tests group_x => sub { ok( 1, 'x' )};
    };
};

1;
