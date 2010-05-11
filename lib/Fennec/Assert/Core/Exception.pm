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

util live_or_die codeblock;
sub live_or_die(&) {
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

=head1 NAME

Fennec::Assert::Core::Exception - Functions to test code that throws exceptions

=head1 DESCRIPTION

Functions to test code that throws warnings. Emulates L<Test::Exception>.

=head1 SYNOPSIS

    dies_ok { die( 'xxx' )} "Should die";
    lives_ok { 1 } "Should live";
    throws_ok { die( 'xxx' )} qr/xxx/, "Throws 'xxx'";
    lives_and { ok( 1, "We did not die" )} "Ooops we died";

=head1 FUNCTIONS

=over 4

=item lives_ok { ... } $name

Test passes if the codeblock does not die.

=item dies_ok { ... } $name

Test passes if the codeblock dies.

=item throws_ok { ... } qr//, $name

Test passes if the codeblock dies, and the thrown message matches the regex.

=item lives_and { ... } $name

Does nothing if the codeblock lives, produces a failed test result if the
codeblock dies.

=back

=head1 INTERNAL API

=head2 FUNCTIONS

=over 4

=item $bool = live_or_die(sub { ... })

=item ( $bool, $msg ) = live_or_die(sub { ... })

Run a codeblock and check if it lives or dies. In array context will return a
boolean, if the code died the error will also be returned. In scalar context
only a boolean will be returned.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
