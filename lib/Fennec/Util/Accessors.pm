package Fennec::Util::Accessors;
use strict;
use warnings;

use base 'Fennec::Base';

use Carp;
use Scalar::Util qw/blessed/;

sub alias {
    my $class = shift;
    my ($caller) = @{ shift(@_) };
    $class->build_accessors( $caller, @_ );
}

sub build_accessors {
    my $class = shift;
    my ( $caller, @list ) = @_;
    for my $accessor ( @list ) {
        my $sub = sub {
            my $self = shift;
            croak ( "$caller\->$accessor() is an object method, not a class method." )
                if $self eq $caller;
            confess( "$accessor() called on something other than an instance of $caller - how'd you do that?" )
                unless blessed($self) and $self->isa( $caller );
            ($self->{ $accessor }) = @_ if @_;
            return $self->{ $accessor };
        };
        no strict 'refs';
        *{ $caller . '::' . $accessor } = $sub;
    }

}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
