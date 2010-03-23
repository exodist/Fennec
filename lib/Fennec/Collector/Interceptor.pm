package Fennec::Collector::Interceptor;
use strict;
use warnings;

use base 'Fennec::Collector';

use Fennec::Util::Accessors;

Accessors qw/intercepted/;

sub cull {}

sub init {
    my $self = shift;
    $self->intercepted([]);
}

sub write {
    my $self = shift;
    my ( $output ) = @_;
    push @{ $self->intercepted } => $output;
}

1;
