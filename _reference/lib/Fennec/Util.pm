package Fennec::Util;
use strict;
use warnings;
use base 'Exporter';
use Scalar::Util qw/blessed/;
use Carp;

our @EXPORT = get_all_subs( __PACKAGE__ );

sub get_all_subs {
    my ( $package ) = @_;
    $package = $package . '::' unless $package =~ m/::$/;
    {
        no strict 'refs';
        return grep { defined( *{$package . $_}{CODE} )} keys %$package;
    }
}

sub add_accessors {
    my $package = caller;
    for my $accessor ( @_ ) {
        my $sub = sub {
            my $self = shift;
            croak( "Did not get blessed self." )
                unless $self and blessed( $self );
            ($self->{ $accessor }) = @_ if @_;
            return $self->{ $accessor };
        };
        no strict 'refs';
        *{ $package . '::' . $accessor } = $sub;
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
