package Fennec::Tester::TestResults;
use strict;
use warnings;
use Fennec::Runner;
use Fennec::Interceptor;

use Fennec::Tester;

our @RESULTS;
our @DIAG;
our @FAILURES;
our @HANDLERS;

util( $_ ) for qw{
    results diags failures push_diag push_results push_failures capture_tests
};

tester( $_ ) for qw{
    produces_like produces diag_is results_are result_ratio_from
    diag_count_from result_count_from result_ratio diag_like diag_count_is
    result_count_is
};

#{{{ Utility functions
sub _results {
    @RESULTS = () if @_;
    return \@RESULTS;
}

sub _diags {
    @DIAG = () if @_;
    return \@DIAG;
}

sub _failures {
    @FAILURES = () if @_;
    return \@FAILURES;
}

sub _push_diag {
    push @DIAG => @_;
}

sub _push_results {
    push @RESULTS => @_;
}

sub _push_failures {
    push @FAILURES => @_;
}

# When things are run under capture_test results should go to @RESULTS, diag should go to @DIAG
sub _capture_tests(&;@) {
    my ( $sub, %opts ) = @_;

    if ( $opts{ clear }) {
        _results(1);
        _diags(1);
        _failures(1);
    }

    _init_handler() unless @HANDLERS;

    # If we are in a sub-process refactor first. We want the results to go to
    # whatever process we are currently in when capture_tests is called. Then
    # any forking done after will send to us.
    Fennec::Runner->get->_sub_process_refactor;

    local Fennec::Runner->get->{ result_handlers } = \@HANDLERS;
    local Fennec::Runner->get->{ failures } = \@FAILURES;

    return $sub->();
}
#}}}

#{{{ Tester functions
sub _result_count_is($;$) {
    my ( $count, $name ) = @_;
    croak( "First argument to result_count_is() must be a number"  )
        unless defined $count && $count =~ m/^\d+$/;

    my $actual = @RESULTS;
    my $ok = $count == $actual ? 1 : 0;
    return ( $ok, $name, $ok ? () : ( "Expected '$count' results, got '$actual'" ) );
};

sub _diag_count_is($;$) {
    my ( $count, $name ) = @_;
    croak( "First argument to diag_count_is() must be a number"  )
        unless defined $count && $count =~ m/^\d+$/;

    my $actual = @DIAG;
    my $ok = $count == $actual ? 1 : 0;
    return ( $ok, $name, $ok ? () : ( "Expected '$count' results, got '$actual'" ) );
};

sub _diag_like($;$) {
    my ( $want, $name ) = @_;
    $want = [ $want ] unless ref $want eq 'ARRAY';
    my @diag;
    my $ok = 1;
    for my $item ( @$want ) {
        croak( "'$item' is not a regexp" )
            unless ref( $item ) eq 'Regexp';
        unless ( grep { $_ =~ $item } @DIAG ) {
            $ok = 0;
            push @diag => "No diag messages matched '$item'";
        }
    }
    return ( $ok, $name, @diag );
}

sub _result_ratio($$;$) {
    my ( $pass, $fail, $name ) = @_;
    croak( "First 2 arguments to result_ratio() must be numbers"  )
        unless defined $pass
            && defined $fail
            && ($pass . $fail) =~ m/^\d+$/;

    my $real_pass = grep { $_->result } @RESULTS;
    my $real_fail = grep { !$_->result } @RESULTS;
    my $ok = ( $pass == $real_pass && $fail == $real_fail ) ? 1 : 0;
    return( $ok, $name, $ok ? () : ( "Expected PASS:FAIL ratio '$pass/$fail', got '$real_pass/$real_fail'" ));
};

sub _result_count_from(&$;$) {
    my ( $sub, $count, $name ) = @_;
    local @RESULTS;
    local @DIAG;
    local @FAILURES;

    _capture_tests( \&$sub );
    return _result_count_is( $count, $name );
}

sub _diag_count_from(&$;$) {
    my ( $sub, $count, $name ) = @_;
    local @RESULTS;
    local @DIAG;
    local @FAILURES;

    _capture_tests( \&$sub );
    return _diag_count_is( $count, $name );
}

sub _result_ratio_from(&$$;$) {
    my ( $sub, $pass, $fail, $name ) = @_;
    local @RESULTS;
    local @DIAG;
    local @FAILURES;

    _capture_tests( \&$sub );
    return _result_ratio( $pass, $fail, $name );
};

sub _results_are($;$) {
    my ( $results, $name ) = @_;
    $results = [ $results ] unless ref $results eq 'ARRAY';
    my $real_results = [map { $_->result } @RESULTS];
    my $bad_result = _array_mismatch_at( $results, $real_results );
    my $ok = 1;
    my @diag;

    unless ( @$real_results == @$results ) {
        $ok = 0;
        push @diag => "result count mismatch, expected '" . scalar(@$results) . "' got '" . scalar(@$real_results) . "'";
    }
    if ( defined $bad_result ) {
        $ok = 0;
        push @diag => "results do not match, first mismatch at element '$bad_result'\n\texpected: '$results->[$bad_result]'\n\tgot: '$real_results->[$bad_result]'"
    }
    return ( $ok, $name, @diag );
}

sub _diag_is($;$) {
    my ( $diag, $name ) = @_;
    $diag = [ $diag ] unless ref $diag eq 'ARRAY';
    my $real_diag = [map { $_->diag } @RESULTS];
    my $bad_diag = _array_mismatch_at( $diag, $real_diag );
    my $ok = 1;
    my @diag;

    unless ( @$real_diag == @$diag ) {
        $ok = 0;
        push @diag => "diag count mismatch, expected '" . scalar(@$diag) . "' got '" . scalar(@$real_diag) . "'";
    }
    if ( defined $bad_diag ) {
        $ok = 0;
        push @diag => "diag do not match, first mismatch at element '$bad_diag'\n\texpected: '$diag->[$bad_diag]'\n\tgot: '$real_diag->[$bad_diag]'"
    }
    return ( $ok, $name, @diag );
}

sub _produces(&$$$;$) {
    my ( $sub, $results, $diag, $name ) = @_;
    $diag = [ $diag ] unless ref $diag eq 'ARRAY';

    local @RESULTS;
    local @DIAG;
    local @FAILURES;

    _capture_tests( \&$sub );
    my ( $ok, undef, @diag ) = _results_are( $results, $name );
    my ( $ok2, undef, @diag2 ) = _diag_is( $diag, $name );
    return (( $ok && $ok2 ? 1 : 0 ), $name, @diag, @diag2 );
}

sub _produces_like(&$$$;$) {
    my ( $sub, $pass, $fail, $diag, $name ) = @_;
    local @RESULTS;
    local @DIAG;
    local @FAILURES;

    _capture_tests( \&$sub );
    my ( $ok, undef, @diag ) = _result_ratio( $pass, $fail, $name );
    my ( $ok2, undef, @diag2 ) = _diag_like( $diag, $name );
    return (( $ok && $ok2 ? 1 : 0 ), $name, @diag, @diag2 );
}
#}}}

sub _init_handler {
    require Fennec::Handler::TestResults;
    @HANDLERS = ( Fennec::Handler::TestResults->new );
}

sub _array_mismatch_at {
    my ( $one, $two ) = @_;
    for my $i ( 0 .. (@$one - 1)) {
        return $i unless "$one->[$i]" eq "$two->[$i]";
    }
    return undef;
}

1;

__END__

=pod

=head1 NAME

Fennec::Tester::TestResults - Make Fennec testable

=head1 DESCRIPTION

These functions are used to run tests and capture their output instead of
actually sending the results to output. You can then retrieve the results and
test that they are what you expect. This is similar to TestBuilder::Tester, the
difference is you work with diag messages and results themselves, no need to
parse TAP.

=head1 SYNOPSYS

    package TEST::MyTest;
    use Fennec testers => [ 'TestResults', 'Simple' ];

    capture_tests {
        diag( "Hi there" );
        ok( 1, "Pass" );
        ok( 0, "Fail );
    } clear => 1;

    results_are([ 1, 0 ], 'Got proper results');
    diag_like( qr/Hi there/, 'Got proper diag' );

    1;

=head1 UTILITY FUNCTIONS

These functions are used to run tests and capture their output instead of
actually sending the results to output. You can then retrieve the results and
test that they are what you expect.

=over 4

=item capture_tests { ...code... } %options

Run a set of tests and capture their output instead of treating them like
normal. Captured output can be retrieved with the results() and diag()
functions.

%options are various configuration options, currently only the clear => BOOL
option is supported. This option will clear previous results and diag messages
prior to recording new output.

=item $arrayref = results()

Returns a ref to the array storing captured results.

=item $arrayref = diags()

Returns a ref to the array storing captured diag messages.

=item $arrayref = failures()

Returns a ref to the array storing captured failure results.

=item push_diag( $diag1, $diag2, ... )

Add a diag message to the array of captured messages.

=item push_results( $result1, $result2, ... )

Add a result to the array of captured results.

=item push_failures( $result1, $result2, ... )

Add a result to the array of captured failures.

=back

=head1 TESTER FUNCTIONS

These are helpers to make testing captured test results easier. The testers
that do not take a coderef act upon the normal diag and result arrays. You must
capture or push output before they will work. The functions that take coderefs
will localise the capture arrays and run your test against results and diag
messages captured only in the coderef. None of these functions will modify the
captured results or diag.

=over 4

=item diag_count_is( $count, $name )

Verify number of diag messages captured.

=item result_count_is()

Verify number of results captured.

=item diag_is( $msg, $name )

=item diag_is([ $msg1, $msg2, ... ], $name )

Exact checking of the diag array. Will fail if any message is slightly
different, or if the messages are not all present, or there are more messages
than were listed.

=item results_are( $ok, $name )

=item results_are([ $ok1, $ok2, ... ], $name )

Exact checking of the results array. Will fail if the number of results are
wrong, or if a result does not match its captured counterpart.

=item result_ratio( $pass, $fail, $name )

Verify the number of passes and failures in captured results.

=item diag_like( qr/.../, $name )

=item diag_like( [qr/.../, qr/.../], $name )

Returns true if every regular expression provided matches at least 1 message.
They all can match the same message, and messgae count doe snto need to match
number fo regex's.

=item result_ratio_from { ... } $pass, $fail, $name;

Like results_ratio() except that it runs against results from the provided
codeblock only.

=item result_count_from { ... } $count, $name

Like results_count() except that it runs against the results from the provided
codeblock only.

=item diag_count_from { ... } $count, $name

Like diag_count() except that it runs against the diag from the provided
codeblock only.

=item produces { ... } \@results, \@diag, $name;

Make sure the provided codeblock produces the exact results and diag messages
specified.

=item produces_like { ... } $pass, $fail, $diag, $name

=item produces_like { ... } $pass, $fail, \@diag, $name

Make sure the provided coceblcok produces the correct number of passes and
failures, and that all diag regex's match at least one diag message.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
