package TEST::Fennec::Tester::TestResults;
use strict;
use warnings;
use Fennec testers => [ 'TestResults' ];

sub init {
    results( 1 );
    failures( 1 );
    diags( 1 );
}

test_set can_do => sub {
    can_ok( __PACKAGE__, qw/ results diags failures push_diag push_results push_failures capture_tests /);
    can_ok(
        __PACKAGE__,
        qw/
            produces_like produces diag_is results_are result_ratio_from
            diag_count_from result_count_from result_ratio diag_like
            diag_count_is result_count_is
        /
    );
};

test_set utils => sub {
    diags( 1 );
    results( 1 );
    failures( 1 );
    is_deeply( results, [], "No results yet" );
    is_deeply( diags, [], "No diags yet" );
    is_deeply( failures, [], "No failures yet" );

    push_results( 'a', 'b', 'c' );
    push_diag( 'd', 'e', 'f' );
    push_failures( 'g', 'h', 'i' );

    is_deeply( results, [ 'a' .. 'c' ], "pushed results" );
    is_deeply( diags, [ 'd' .. 'f' ], "pushed diags" );
    is_deeply( failures, [ 'g' .. 'i' ], "pushed failures" );

    capture_tests {
        ok( 1, "one" );
        diag( "hi" );
        ok( 0, "fail" );
    };

    is( @{ results() }, 5, "captured results" );
    is( @{ diags() }, 4, "captured diags" );
    is( @{ failures() }, 4, "captured failures" );
};

test_set helper => sub {
    is(
        Fennec::Tester::TestResults::_array_mismatch_at(
            [ 0 .. 4, 'a' ],
            [ 0 .. 4, 'b' ],
        ),
        5,
        "array compare"
    );
};

test_set 'diag_testers' => sub {
    # diag_count_is
    diags( 1 );
    results( 1 );
    push_diag( 'a' );
    diag_count_is( 1 );
    push_diag( 'a' );
    diag_count_is( 2 );
    capture_tests {
        diag_count_is( 3 );
    };
    is( results->[-1]->result, 0 );

    # diag_like
    # diag_is
};

sub set_xxxx {

}

test_set 'xxx' => sub {

    # result_count_is
    # result_ratio
    # results_are

    # diag_count_from

    # result_ratio_from
    # result_count_from

    # produces_like
    # produces
};

1;

__END__


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

