#!/usr/bin/perl;
use strict;
use warnings;

use Test::Suite::PluginTester;
use Test::More;

my $CLASS;
BEGIN {
    $CLASS = 'Test::Suite::Plugin::Simple';
    use_ok( $CLASS );

    # We export ok, rename it to my_ok and use Test::More's ok()
    no strict 'refs';
    no warnings 'redefine';
    my $ok = \&ok;
    {
        local $SIG{__WARN__} = sub {};
        $CLASS->export_to( __PACKAGE__ );
    }
    *{'my_ok'} = \&ok;

    no warnings 'prototype';
    *{'ok'} = $ok;
}

ok( my_ok( "result", "name" ), "Returns true" );
ok( results->[0]->{ result }, "result is true" );
is( results->[0]->{ name }, "name", "Proper name" );

ok( !my_ok( 0, "name" ), "Returns false" );
ok( !results->[-1]->{ result }, "result is false" );
is( results->[-1]->{ name }, "name", "Proper name" );

done_testing;
