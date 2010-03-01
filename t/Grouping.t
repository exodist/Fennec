#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;

my $CLASS;
BEGIN {
    $CLASS = 'Test::Suite::Grouping';
    use_ok( $CLASS );
    $CLASS->export_to( __PACKAGE__ );
}

can_ok( __PACKAGE__, qw/test_set test_case/ );

sub add_set {
    return "set added";
}

sub add_case {
    return "case added";
}

is( add_set( 'a', sub {1} ), 'set added', 'Set added' );
is( add_case( 'a', sub {1} ), 'case added', 'Case added' );

is( add_set( 'a', method => sub {1} ), 'set added', 'Set added' );
is( add_case( 'a', method => sub {1} ), 'case added', 'Case added' );

throws_ok { test_set( [] )}
          qr/You must provide a set name, and it must not be a reference at/,
          "Bad name";

throws_ok { test_case( [] )}
          qr/You must provide a case name, and it must not be a reference at/,
          "Bad name";

done_testing;
