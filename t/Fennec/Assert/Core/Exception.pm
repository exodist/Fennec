package TEST::Fennec::Assert::Core::Exception;
use strict;
use warnings;

use Fennec;

our $CLASS = 'Fennec::Assert::Core::Exception';

tests use_test_exception => sub {
    use_ok $CLASS;
    my $self = shift;
    can_ok( $self, qw/lives_ok dies_ok throws_ok lives_and/ );
    my $ac = anonclass( use => $CLASS );
    can_ok( $ac->class, qw/lives_ok dies_ok throws_ok lives_and/ );
};

tests lives_ok => sub {
    my $results = capture {
        lives_ok { 1 } 'lives';
        lives_ok { die ( 'xxx' )} 'dies';
        lives_ok { 1 };
    };
    is( @$results, 3, "3 results" );
    is( $results->[0]->name, "lives", "correct name" );
    is( $results->[0]->pass, 1, "passed" );
    is( $results->[1]->name, "dies", "correct name" );
    is( $results->[1]->pass, 0, "failed" );
    is( @{ $results->[1]->stderr }, 1, "1 message" );
    like(
        $results->[1]->stderr->[0],
        qr/xxx at/,
        "useful message"
    );


};

1;

__END__

tester 'lives_ok';
sub lives_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    result(
        pass => $ok ? 1 : 0,
        name => $name || 'nameless test',
    );
}

tester 'dies_ok';
sub dies_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    result(
        pass => !$ok ? 1 : 0,
        name => $name || 'nameless test',
    );
}

tester 'throws_ok';
sub throws_ok(&$;$) {
    my ( $code, $reg, $name ) = @_;
    my ( $ok, $msg ) = live_or_die( $code );
    my ( $pkg, $file, $number ) = caller;

    # If we lived
    return result(
        pass => !$ok ? 1 : 0,
        name => $name || 'nameless test',
        stdout => ["Test did not die as expected at $file line $number"],
    ) if $ok;

    my $match = $msg =~ $reg ? 1 : 0;
    my @diag = ("$file line $number:\n  Wanted: $reg\n  Got: $msg" )
        unless( $match );

    return result(
        pass => $match ? 1 : 0,
        name => $name || 'nameless test',
        stdout => \@diag,
    );
}

tester 'lives_and';
sub lives_and(&;$) {
    my ( $code, $name ) = @_;
    my ( $ok, $msg )= live_or_die( $code );
    my ( $pkg, $file, $number ) = caller;
    chomp( $msg );
    $msg =~ s/\n/ /g;
    return if $ok;

    return result(
        pass => 0,
        name => $name || 'nameless test',
        stdout => ["Test unexpectedly died: '$msg' at $file line $number"],
    );
}

sub live_or_die {
    my ( $code ) = @_;
    my $return = eval { $code->(); 'did not die' } || "died";
    my $msg = $@;

    if ( $return eq 'did not die' ) {
        return ( 1, $return ) if wantarray;
        return 1;
    }
    else {
        return 0 unless wantarray;

        if ( !$msg ) {
            carp "code died as expected, however the error is masked. This"
               . " can occur when an object's DESTROY() method calls eval";
        }

        return ( 0, $msg );
    }
}

1;
