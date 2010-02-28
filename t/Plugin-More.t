#!/usr/bin/perl;
use strict;
use warnings;

use Test::Suite::TestHelper;
use Test::More;

my $CLASS;
BEGIN {
    $CLASS = 'Test::Suite::Plugin::More';
    use_ok( $CLASS );
    $CLASS->export_to( __PACKAGE__, 'my_' );
}

can_ok( __PACKAGE__, @Test::Suite::Plugin::More::SUBS );

my_is_deeply( { a => 'a' }, { 'a' => 'a' }, "My is_deeply()" );
real_tests {
    ok( results->[-1]->{result}, "passed" );
    is( results->[-1]->{name}, "My is_deeply()", "Correct name" );
    ok( !results->[-1]->{todo}, "Was not todo" );
};

my_todo {
    my_is_deeply( { a => 'a' }, { 'a' => 'b' }, "TODO test" );
    real_tests {
        ok( !results->[-1]->{result}, "failes" );
        is( results->[-1]->{name}, "TODO test", "Correct name" );
        is( results->[-1]->{todo}, "This is a todo", "Was TODO" );
    };
} "This is a todo";

my_is_deeply( { a => 'a' }, { 'a' => 'a' }, "My is_deeply()" );
real_tests {
    ok( results->[-1]->{result}, "passed" );
    is( results->[-1]->{name}, "My is_deeply()", "Correct name" );
    ok( !results->[-1]->{todo}, "Was not todo" );
};

done_testing;
