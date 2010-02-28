#!/usr/bin/perl;
use strict;
use warnings;

use Test::Suite::TestHelper;
use Test::More;
use Object::Quick qw/obj method/;

my $CLASS;
BEGIN {
    $CLASS = 'Test::Suite::Plugin::Exception';
    real_tests { use_ok( $CLASS ) };
    $CLASS->export_to( __PACKAGE__ );
    *live_or_die = \&Test::Suite::Plugin::Exception::live_or_die;
}

# Exception is not a wrapper around a TB based implementation, all tests are
# real.
real_tests {
    dies_ok { 1 } "dies_ok fail";
    ok( !results->[-1]->{result}, "fail result" );
    is( results->[-1]->{name}, 'dies_ok fail', "fail name" );

    lives_ok { die( 'xxx' )} 'lives_ok fail';
    ok( !results->[-1]->{result}, "fail result" );
    is( results->[-1]->{name}, 'lives_ok fail', "fail name" );

    throws_ok { 1 } qr/xxx/, "throws_ok doesn't die";
    ok( !results->[-1]->{result}, "fail result" );
    is( results->[-1]->{name}, 'throws_ok doesn\'t die', "fail name" );

    throws_ok { die "XXX" } qr/YYY/, "throws_ok error doesn't match";
    ok( !results->[-1]->{result}, "fail result" );
    is( results->[-1]->{name}, 'throws_ok error doesn\'t match', "fail name" );

    lives_and { die 'xxx' } "did not live to test";
    ok( !results->[-1]->{result}, "fail result" );
    is( results->[-1]->{name}, 'did not live to test', "fail name" );

    my $ret = live_or_die( sub { die( 'apple' ) });
    ok( !$ret, "Registered a die" );

    ($ret, my $error) = live_or_die( sub { die( 'apple' ) });
    ok( !$ret, "Registered a die" );
    like( $error, qr/apple/, "Got error" );

    $ret = live_or_die( sub { 1 });
    ok( $ret, "Registered a live" );

    ($ret, my $msg) = live_or_die( sub { 1; });
    ok( $ret, "Registered a live" );
    like( $msg, qr/did not die/, "Got msg" );

    {
        my @warn;
        local $SIG{ __WARN__ } = sub { push @warn => @_ };

        ($ret, $error) = live_or_die( sub {
            my $obj = obj( DESTROY => method { eval { 1 }} );
            die( 'apple' );
            $obj->x;
        });
        ok( !$ret, "Registered a die despite eval in DESTROY" );
        ok( !$error, "Error was masked by eval in DESTROY" );
        like(
            $warn[0],
            qr/
                code \s died \s as \s expected, \s however \s the \s error \s is \s
                masked\. \s This \s can \s occur \s when \s an \s object's \s
                DESTROY\(\) \s method \s calls \s eval \s at \s .*$0
            /sx,
            "Warn of edge case"
        );

        @warn = ();
        $ret = live_or_die( sub {
            my $obj = obj( DESTROY => method { eval { 1 }} );
            die( 'apple' );
            $obj->x;
        });
        ok( !$ret, "Registered a die despite eval in DESTROY" );
        ok( !@warn, "No warning when error is not requested" );

        @warn = ();
        throws_ok {
            my $obj = obj( DESTROY => method { eval { 1 }} );
            die( 'xxx' );
            $obj->x;
        } qr/^$/, "Throw edge case";

        like(
            $warn[0],
            qr/
                code \s died \s as \s expected, \s however \s the \s error \s is \s
                masked\. \s This \s can \s occur \s when \s an \s object's \s
                DESTROY\(\) \s method \s calls \s eval \s at \s .*$0
            /sx,
            "Warn of edge case"
        );

        ok( results->[-1]->{ result }, "pass" );
        is( results->[-1]->{ name }, "Throw edge case", "Throw edge case" );
    }

    lives_ok { 1 } "Simple living sub";
    ok( results->[-1]->{ result }, "pass" );
    is( results->[-1]->{ name }, "Simple living sub", "Correct name" );

    dies_ok { die( 'xxx' )} "Simple dying sub";
    ok( results->[-1]->{ result }, "pass" );
    is( results->[-1]->{ name }, "Simple dying sub", "Correct name" );

    throws_ok { die( 'xxx' )} qr/xxx/, "Simple throw";
    ok( results->[-1]->{ result }, "pass" );
    is( results->[-1]->{ name }, "Simple throw", "Correct name" );

    # On success no test should be recorded for lives_and
    lives_and { ok( 1, "Blah" )} "Test did not die";
    ok( results->[-1]->{ name } ne "Test did not die", "No test recorded" );
};

done_testing;
