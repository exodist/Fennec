package TEST::Fennec::Assert::Core::Simple;
use strict;
use warnings;

use Fennec;

our $CLASS = 'Fennec::Assert::Core::Simple';

tests 'todo tests' => sub {
    my $output = capture {
        TODO {
            ok( 0, "Fail" );
            ok( 1, "Pass" );
            is_deeply(
                [qw/a b c/],
                [ 'a' .. 'c'],
                "Pass"
            );
            is_deeply(
                [qw/a b c/],
                [ 'x' .. 'z' ],
                "Fail"
            );
        } "Havn't gotten to it yet";
        TODO { ok( 0, 'fail' )};
    };
    is( @$output, 5, "5 results" );
    is( pop(@$output)->todo, "no reason given", "auto-todo reason" );
    is( $_->todo, "Havn't gotten to it yet", "Result has todo" )
        for @$output;
    result_line_numbers_are( $output, map { ln($_) } -19, -18, -17, -12 );

    $output = capture {
        TODO { die( 'I dies badly' )} "This will die";
    };
    like(
        $output->[0]->stderr->[0],
        qr/Caught error in todo block\n  Error: I dies badly.*\n  todo: This will die/s,
        "Convey problem"
    );
};

tests 'utils' => sub {
    my $output = capture {
        diag "hi there", "blah";
    };
    is( @$output, 1, "1 output" );
    is_deeply(
        $output->[0],
        {
            stderr => [ "hi there", "blah" ],
            #Can't really predict
            timestamp => $output->[0]->timestamp,
        },
        "Proper diag"
    );
};

tests 'ok' => sub {
    my $output = capture {
        ok( 1, 'pass' );
        ok( 0, 'fail' );
        ok( 1 );
        ok( 0 );
    };

    is( @$output, 4, "4 results" );
    is( $output->[0]->pass, 1, "passed" );
    is( $output->[0]->name, 'pass', 'name' );
    is( $output->[1]->pass, 0, "failed" );
    is( $output->[1]->name, 'fail', 'name' );
    is( $output->[2]->pass, 1, "passed" );
    is( $output->[2]->name, 'nameless test', 'name' );
    is( $output->[3]->pass, 0, "failed" );
    is( $output->[3]->name, 'nameless test', 'name' );
};

1;
