package Fennec::Util;
use strict;
use warnings;
use Exporter::Declare;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;

exports qw/inject_sub accessors get_test_call/;

sub inject_sub {
    my ( $package, $name, $code ) = @_;
    croak "inject_sub() takes a package, a name, and a coderef"
        unless $package
            && $name
            && $code
            && $code =~ /CODE/;

    no strict 'refs';
    *{"$package\::$name"} = $code;
}

sub accessors {
    my $caller = caller;
    _accessor( $caller, $_ ) for @_;
}

sub _accessor {
    my ( $caller, $attribute ) = @_;
    inject_sub( $caller, $attribute, sub {
        my $self = shift;
        croak "$attribute() called on '$self' instead of an instance"
            unless blessed( $self );
        ( $self->{$attribute} ) = @_ if @_;
        return $self->{$attribute};
    });
}

sub get_test_call {
    my $runner;
    my $i = 1;

    while ( my @call = caller( $i++ )) {
        $runner = \@call if !$runner && $call[0]->isa('Fennec::Runner');
        return @call if $call[0]->can('FENNEC');
    }

    return( @$runner );
}

sub tb_ok         { Test::Builder->new->ok( @_ )        }
sub tb_diag       { Test::Builder->new->diag( @_ )      }
sub tb_skip       { Test::Builder->new->skip( @_ )      }
sub tb_todo_start { Test::Builder->new->todo_start( @_ )}
sub tb_todo_end   { Test::Builder->new->todo_end        }

1;

__END__

=head1 NAME

Fennec::Util - Utility functions

=head1 DESCRIPTION

This class provides useful utility functions used all over Fennec.

=head1 EXPORTS

=over 4

=item inject_sub( $package, $name, $code )

Inject a sub into a package.

=item accessors( @attributes )

Generate basic accessors for the given attributes into the calling package.

=item @call = get_test_call()

Look back through the stack and find the last call that took place in a test
class.

=back

=head1 API STABILITY

Fennec versions below 1.000 were considered experimental, and the API was
subject to change. As of version 1.0 the API is considered stabalized. New
versions may add functionality, but not remove or significantly alter existing
functionality.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
