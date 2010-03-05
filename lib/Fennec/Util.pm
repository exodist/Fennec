package Fennec::Util;
use strict;
use warnings;
use base 'Exporter';

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
            ($self->{ $accessor }) = @_ if @_;
            return $self->{ $accessor };
        };
        no strict 'refs';
        *{ $package . '::' . $accessor } = $sub;
    }
}

1;
