#!/usr/bin/perl;
use strict;
use warnings;

use Test::Suite::TestHelper;
use Test::More;

my $CLASS;
BEGIN {
    $CLASS = 'Test::Suite::Plugin::Simple';
    real_tests { use_ok( $CLASS )};
    $CLASS->export_to( __PACKAGE__, 'my_' );
}

real_tests {
    ok( my_ok( "result", "name" ), "Returns true" );
    ok( results->[0]->{ result }, "result is true" );
    is( results->[0]->{ name }, "name", "Proper name" );

    ok( !my_ok( 0, "name" ), "Returns false" );
    ok( !results->[-1]->{ result }, "result is false" );
    is( results->[-1]->{ name }, "name", "Proper name" );
};

done_testing;
