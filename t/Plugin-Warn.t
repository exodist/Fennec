#!/usr/bin/perl;
use strict;
use warnings;

use Test::Suite::PluginTester;
use Test::More;

my $CLASS;
BEGIN {
    $CLASS = 'Test::Suite::Plugin::Warn';
    use_ok( $CLASS );
    $CLASS->export_to( __PACKAGE__ );
}

can_ok( __PACKAGE__, @Test::Suite::Plugin::Warn::SUBS );

warning_is { warn 'a' } "a", "got warning";
ok( results->[-1]->{result}, "Pass" );
is( results->[-1]->{name}, "got warning", "got name" );
ok( !@{ diags() }, "no diags" );

warning_is { warn 'a' } "b", "fail warning";
ok( !results->[-1]->{result}, "Fail" );
is( results->[-1]->{name}, "fail warning", "got name" );
is_deeply(
    [ map { my $x = $_; $x =~ s/\s+at.*$//s; $x } @{ diags() }],
    [
        "found warning: a",
        "expected to find warning: b",
    ],
    "Got diags"
);
is( @{diags()}, 2, "2 diags" );

done_testing;
