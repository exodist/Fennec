#!/usr/bin/perl;
use strict;
use warnings;

use Test::Suite::TestHelper;
use Test::More;

my $CLASS;
BEGIN {
    $CLASS = 'Test::Suite::Plugin::Warn';
    use_ok( $CLASS );
    $CLASS->export_to( __PACKAGE__ );
}

can_ok( __PACKAGE__, @Test::Suite::Plugin::Warn::SUBS );

warning_is { warn 'a' } "a", "got warning";
real_tests {
    ok( results->[-1]->{result}, "Pass" );
    is( results->[-1]->{name}, "got warning", "got name" );
    ok( !@{ results->[-1]->{debug} }, "no diags" );
};

warning_is { warn 'a' } "b", "fail warning";
real_tests {
    ok( !results->[-1]->{result}, "Fail" );
    is( results->[-1]->{name}, "fail warning", "got name" );
    is_deeply(
        [ map { my $x = $_; $x =~ s/\s+at.*$//s; $x } @{ results->[-1]->{debug} }],
        [
            "found warning: a",
            "expected to find warning: b",
        ],
        "Got diags"
    );
};

done_testing;
