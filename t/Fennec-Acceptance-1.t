#!/usr/bin/perl
use strict;
use warnings;

my $tester;
BEGIN {
    require Fennec::Tester;
    $tester = Fennec::Tester->new( _config => 1, no_load => 1, files => []);
}

{
    package MyTest;
    use Fennec random => 1;

    test_case 'a' => sub {1};
    test_case 'b' => sub {1};
    test_case 'c' => sub {1};
    test_case 'd' => sub {1};

    test_case 'e' => (
        method => sub { die( "try/catch should keep the tests going, todo will keep this from failing" ) },
        todo => "This dies",
    );

    test_case 'f' => (
        method => sub { die( "try/catch should not see me" ) },
        skip => "This dies",
    );

    test_set set_a => sub {
        ok( 1, "Simple ok set a" );
    };

    test_set set_b => sub {
        ok( 1, "Simple ok set b" );
    };

    test_set set_c => sub {
        ok( 1, "Simple ok set c" );
    };

    test_set set_d => sub {
        ok( 1, "Simple ok set d" );
    };

    test_set set_e => sub {
        is_deeply( { a => 'a' }, { a => 'a' }, "is_deeply" );
    };

    test_set set_f => (
        method => sub { ok( 0, "Will not pass" )},
        todo => 'is 0',
    );

    test_set set_g => (
        method => sub { die( "Should not see me" ) },
        skip => "This will die",
    );

    test_set set_h => (
        method => sub { die( "try/catch should keep the tests going, todo will keep this from failing" ) },
        todo => "This dies",
    );
}

$tester->run;


1;
