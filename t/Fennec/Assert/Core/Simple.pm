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
    };
    is( @$output, 4, "4 results" );
    is( $_->todo, "Havn't gotten to it yet", "Result has todo" )
        for @$output;
    result_line_numbers_are( $output, map { ln($_) } -17, -16, -15, -10 );

    $output = capture {
        TODO { die( 'I dies badly' )} "This will die";
    };
    like(
        $output->[0]->stdout->[0],
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
        { stdout => [ "hi there", "blah" ]},
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

__END__

tester 'require_ok';
sub require_ok(*) {
    my ( $package ) = @_;
    try {
        eval "require $package" || die( $@ );
        result(
            pass => 1,
            name => "require $package",
        );
    }
    catch {
        result(
            pass => 0,
            name => "require $package",
            stdout => [ $_ ],
        );
    };
};

tester 'use_into_ok';
sub use_into_ok(**;@) {
    my ( $from, $to, @importargs ) = @_;
    my $run = "package $to; $from->import";
    $run .= '(@_)' if @importargs;
    try {
        eval "require $from; 1" || die( $@ );
        eval "$run; 1" || die( $@ );
        result(
            pass => 1,
            name => "$from\->import(...)",
        );
    }
    catch {
        return result(
            pass => 0,
            name => "$from\->import(...)",
            stdout => [ $_ ],
        );
    }
};

tester use_ok => sub(*) {
    my( $from, @importargs ) = @_;
    my $caller = caller;
    use_into_ok( $from, $caller, @importargs );
};

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
