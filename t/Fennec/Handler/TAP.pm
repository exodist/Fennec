package TEST::Fennec::Handler::TAP;
use strict;
use warnings;

use Fennec;
use Fennec::Util::Alias qw/
    Fennec::Output::Result
    Fennec::Output::Diag
/;

our $CLASS = 'Fennec::Handler::TAP';
use_ok $CLASS;

tests 'create' => sub {
    my $one = $CLASS->new( out_std => sub {}, out_err => sub {} );
    isa_ok( $one, $CLASS );
    can_ok( $one, qw/handle fennec_error finish/ );
};

tests 'verbose' => sub {
    local $ENV{HARNESS_ACTIVE} = 1;
    local $ENV{HARNESS_IS_VERBOSE} = 1;
    my $one = $CLASS->new( out_std => sub {} );
    is( $one->{ out_err }, $one->{ out_std }, "verbose sends err to std" );

    local $ENV{HARNESS_ACTIVE} = 0;
    local $ENV{HARNESS_IS_VERBOSE} = 0;
    $one = $CLASS->new( out_std => sub {} );
    is( $one->{ out_err }, $one->{ out_std }, "no harness - send err to std" );
};

tests 'verbose' => sub {
    local $ENV{HARNESS_ACTIVE} = 1;
    local $ENV{HARNESS_IS_VERBOSE} = 0;
    my $one = $CLASS->new( out_std => sub {} );
    isnt( $one->{ out_err }, $one->{ out_std }, "non-verbose sends err to err" );
};

tests 'count' => sub {
    my $one = $CLASS->new( out_std => sub {}, out_err => sub {} );
    is( $one->_test_count, "0001", "First count" );
    is( $one->_test_count, "0002", "Increment" );
    is( $one->_test_count, "0003", "Increment again" );
};

tests 'handle' => sub {
    my ( @err, @out );
    my $one = $CLASS->new(
        out_std => sub { @out = @_ },
        out_err => sub { @err = @_ },
    );
    $one->handle( Result->new( pass => 1 ));
    is( @out, 1, "Result output in out" );
    $one->handle( Result->new( pass => 0 ));
    is( @out, 1, "Result output" );

    $one->handle( Diag->new( stderr => [ "a" ]));
    is( @err, 1, "diag message" );
    is( $err[0], "# a", "Got message" );

    warning_like { $one->handle( bless( {}, 'XXX' ))}
        qr/Unhandled output type: XXX=HASH/,
        "Unhandled output";

    warning_like { $one->handle }
        qr/No item at/,
        "No item warning";
};

tests result => sub {
    # Put tests in coderef, localize subs, run tests.
    my ( $line, $diag ) = ( 0,0 );
    my $run = sub {
        my $one = $CLASS->new( out_std => sub {1}, out_err => sub {1} );
        $one->result();
        ok( !$line && !$diag, "Nothing w/o a result" );
        $one->result( 1 );
        is( $line, 1, "Generate a line" );
        is( $diag, 1, "Diag" );
    };
    no strict 'refs';
    no warnings 'redefine';
    local *{ $CLASS . '::_result_line' } = sub { $line++ };
    local *{ $CLASS . '::_result_diag' } = sub { $diag++ };
    $run->();
};

tests 'output' => sub {
    my ( $err, $out );
    my $one = $CLASS->new( out_std => sub { ($out) = @_ }, out_err => sub { ($err) = @_ });
    $one->_output( 'out_std', "hi" );
    $one->_output( 'out_err', "bye" );
    is( $out, 'hi', "Send std" );
    is( $err, 'bye', "Send err" );

    $one->stdout( 'a' );
    is( $out, '# a', "stdout" );

    $one->stderr( 'a' );
    is( $err, '# a', "stderr" );
};

tests 'finish' => sub {
    my ( $out );
    my $one = $CLASS->new( out_std => sub { ($out) = @_ }, out_err => sub {1});
    $one->_test_count for 1 .. 5;
    $one->finish;
    is( $out, '1..5', "Test count" );
};

tests 'internal error' => sub {
    my ( $err, $out );
    my $one = $CLASS->new( out_std => sub { ($out) = @_ }, out_err => sub { ($err) = @_ });
    $one->fennec_error( 'a' );
    is( $out, "not ok 0001 - Fennec Internal error", "Internal error is not ok" );
    is( $err, '# a', "Show error" );
};

tests 'benchmark string' => sub {
    my $one = $CLASS->new;
    is( $one->_benchmark(), '[ N/A  ]', "no benchmark" );
    is( $one->_benchmark([0.0002]), '[0.0002]', "fraction of a second" );
    is( $one->_benchmark([0.1]), '[0.1000]', "10'th of a second" );
    is( $one->_benchmark([1]), '[1.0000]', "second" );
    is( $one->_benchmark([10]), '[10.000]', "10 seconds" );
    is( $one->_benchmark([99]), '[99.000]', "> 10 seconds" );
    is( $one->_benchmark([100]), '[000100]', "100 seconds" );
    is( $one->_benchmark([999]), '[000999]', "> 100 seconds" );
    is( $one->_benchmark([100000]), '[100000]', "6 digits" );
    is( $one->_benchmark([1000000]), '[1000000]', "7 digits" );
};

tests status => sub {
    my $one = $CLASS->new;
    is(
        $one->_status( Result->new( pass => 1 )),
        "ok",
        "Pass is 'ok'"
    );
    is(
        $one->_status( Result->new( pass => 0 )),
        "not ok",
        "Fail is 'not ok'"
    );
    is(
        $one->_status( Result->new( pass => 0, skip => 1 )),
        "ok",
        "skip is 'ok'"
    );
    is(
        $one->_status( Result->new( pass => 0, todo => 1 )),
        "not ok",
        "Skip is 'not ok'"
    );
    is(
        $one->_status( Result->new( pass => 1, todo => 1 )),
        "ok",
        "Pass todo is 'ok'"
    );
};

tests postfix => sub {
    my $one = $CLASS->new;
    is(
        $one->_postfix( Result->new( todo => "aaa" )),
        "# TODO aaa",
        "TODO"
    );
    is(
        $one->_postfix( Result->new( skip => "aaa" )),
        "# SKIP aaa",
        "skip"
    );
    is(
        $one->_postfix( Result->new()),
        "",
        "none is empty string"
    );
};

tests result_line => sub {
    my ( $err, $out );
    my $one = $CLASS->new( out_std => sub { ($out) = @_ }, out_err => sub { ($err) = @_ });
    $one->_result_line( Result->new( pass => 1, name => 'hello world' )),
    like(
        $out,
        qr/ok 0001 \[[\d.]+\] - hello world/,
        "result line"
    );
    $one->_result_line( Result->new( pass => 1, name => undef )),
    like(
        $out,
        qr/ok 0002 \[[\d.]+\] - \[UNNAMED TEST: unknown file line unknown \]/,
        "unamed result line"
    );
};

tests 'result diag' => sub {
    my ( $err, $out );
    my $one = $CLASS->new( out_std => sub { ($out) = @_ }, out_err => sub { ($err) = @_ });
    $one->_result_diag( Result->new( pass => 1, stderr => [ 'a' ], stdout => [ 'b' ] ));
    is( $err, '# a', "stderr" );
    is( $out, '# b', "stdout" );

    $one->_result_diag( Result->new( pass => 0, file => 'a', line => 1 ));
    is( $err, "# Test failure at a line 1", "failure diag" );

    $err = undef;
    $one->_result_diag( Result->new( pass => 0, file => 'a', line => 1, todo => 1 ));
    is( $err, undef, "failure diag todo" );

    $err = undef;
    $one->_result_diag( Result->new( pass => 0, file => 'a', line => 1, skip => 1 ));
    is( $err, undef, "failure diag skip" );

    $one->_result_diag( Result->new( pass => 0, workflow_stack => [ 'a', 'b', 'c' ]));
    is( $err, "# Workflow Stack: a, b, c", "workflow stack" );
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
