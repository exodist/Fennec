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
                "Pass TB"
            );
            is_deeply(
                [qw/a b c/],
                [ 'x' .. 'z' ],
                "Fail TB"
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

1;

__END__

util diag => \&diag;

tester ok => sub {
    my ( $ok, $name ) = @_;
    result(
        pass => $ok ? 1 : 0,
        name => $name || 'nameless test',
    );
};

tester 'require_ok';
sub require_ok(*) {
    my ( $package ) = @_;
    try {
        eval "require $package" || die( $@ );
    }
    catch {
        result(
            pass => 0,
            name => "require $package",
            stdout => [ $_ ],
        );
    };
    result(
        pass => 1,
        name => "require $package",
    );
};

tester 'use_into_ok';
sub use_into_ok(**;@) {
    my ( $from, $to, @importargs ) = @_;
    require_ok( $from );
    my $run = "package $to; $from->import";
    $run .= '(@_)' if @importargs;
    try {
        eval $run || die( $@ );
    }
    catch {
        result(
            pass => 0,
            name => "$from\->import(...)",
            stdout => [ $_ ],
        );
    }
    result(
        pass => 1,
        name => "$from\->import(...)",
    );
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
