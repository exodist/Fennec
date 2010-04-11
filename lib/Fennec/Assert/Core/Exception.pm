package Fennec::Assert::Core::Exception;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
use Try::Tiny;
use Carp;

tester 'lives_ok';
sub lives_ok(&;$) {
    my ( $code, $name ) = @_;
    my ($ok, $msg) = live_or_die( $code );
    result(
        pass => $ok ? 1 : 0,
        name => $name || 'nameless test',
        $msg ? (stderr => [ $msg ]) : (),
    );
}

tester 'dies_ok';
sub dies_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    result(
        pass => !$ok ? 1 : 0,
        name => $name || 'nameless test',
        $ok ? ( stderr => ['Did not die as expected'] ) : (),
    );
}

tester 'throws_ok';
sub throws_ok(&$;$) {
    my ( $code, $reg, $name ) = @_;
    my ( $ok, $msg ) = live_or_die( $code );

    # If we lived
    return result(
        pass => !$ok ? 1 : 0,
        name => $name || 'nameless test',
        stderr => ["Test did not die as expected"],
    ) if $ok;

    my $match = $msg =~ $reg ? 1 : 0;
    my @diag = ("Wanted: $reg", "Got: $msg" )
        unless( $match );

    return result(
        pass => $match ? 1 : 0,
        name => $name || 'nameless test',
        stderr => \@diag,
    );
}

util 'lives_and';
sub lives_and(&;$) {
    my ( $code, $name ) = @_;
    my ( $ok, $msg ) = live_or_die( $code );
    return if $ok;

    if ( $msg ) {
        chomp( $msg );
        $msg =~ s/\n/ /g;
    }

    return result(
        pass => 0,
        name => $name || 'nameless test',
        stderr => ["Test unexpectedly died: '$msg'"],
    );
}

sub live_or_die {
    my ( $code ) = @_;
    my $return = eval { $code->(); 'did not die' } || "died";
    my $msg = $@;

    if ( $return eq 'did not die' ) {
        return 1;
    }
    else {
        return 0 unless wantarray;

        if ( !$msg ) {
            warn "code died as expected, however the error is masked. This"
               . " can occur when an object's DESTROY() method calls eval\n";
        }

        return ( 0, $msg );
    }
}

1;
