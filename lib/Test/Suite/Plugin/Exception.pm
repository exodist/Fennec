package Test::Suite::Plugin::Exception;
use strict;
use warnings;

#{{{ POD

=head1 NAME

Test::Suite::Plugin::Exception - Test::Exception functionality for L<Test::Suite>

=head1 CREDITS

This code is modified from L<Test::Exception::LessClever> which is a simpler
re-write of L<Test::Exception>

=cut

#}}}

use Test::Suite::Plugin;
use Carp;

our @CARP_NOT = ( __PACKAGE__, 'Test::Suite::Plugin' );

=head1 TEST FUNCTIONS

=over 4

=item lives_ok( sub { ... }, $name )

Test passes if the sub does not die, false if it does.

=cut

tester 'lives_ok';
sub _lives_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    return ( $ok, $name );
}

=item dies_ok( sub { ... }, $name )

Test passes if the sub dies, false if it does not.

=cut

tester 'dies_ok';
sub _dies_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    return ( !$ok, $name );
}

=item throws_ok( sub { ... }, qr/message/, $name )

Check that the sub dies, and that it throws an error that matches the regex.

Test fails is the sub does not die, or if the message does not match the regex.

=cut

tester 'throws_ok';
sub _throws_ok(&$;$) {
    my ( $code, $reg, $name ) = @_;
    my ( $ok, $msg ) = live_or_die( $code );
    my ( $pkg, $file, $number ) = caller;

    # If we lived
    return ( !$ok, $name, "Test did not die as expected at $file line $number." )
        if ( $ok );

    my $match = $msg =~ $reg ? 1 : 0;
    my @diag = ("$file line $number:\n  Wanted: $reg\n  Got: $msg" )
        unless( $match );

    return ( $match, $name, @diag );
}

=item lives_and( sub {...}, $name )

Fails with $name if the sub dies, otherwise is passive. This is useful for
running a test that could die. If it dies there is a failure, fi ti lives it is
responsible for itself.

=cut

tester 'lives_and';
sub _lives_and(&;$) {
    my ( $code, $name ) = @_;
    my ( $ok, $msg )= live_or_die( $code );
    my ( $pkg, $file, $number ) = caller;
    chomp( $msg );
    $msg =~ s/\n/ /g;
    return no_test() if $ok;
    return( $ok, $name, "Test unexpectedly died: '$msg' at $file line $number." );
}

=back

=head1 INTERNAL API

=over 4

=item $status = live_or_die( sub { ... }, $name )

=item ($status, $msg) = live_or_die( sub { ... }, $name )

Check if the code lives or dies. In scalar context returns true or false. In
array context returns the same true or false with the error message. If the
return is true the error message will be something along the lines of 'did not
die' but this may change in the future.

Will generate a warning if the test dies, $@ is empty AND called in array
context. This usually occurs when an objects DESTROY method calls eval and
masks $@.

=cut

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

__END__

=back

=head1 SEE ALSO

L<Test::Exception> - Original Test::Exception functionality

L<Test::Exception::LessClever> - Exodist's less clever re-write (which was
copied for this version)

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
