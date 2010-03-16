package Fennec::Group::Root;
use strict;
use warnings;
use Carp;

use base 'Fennec::Group';

sub depends {[ 'Fennec::Group::Tests' ]}

sub add_item {
}

sub tests {
}

sub build {
    my $self = shift;
    my $tclass = $self->run_method_as_current( $self->method );
    $self->parent( $tclass->new( group => $self, file => $self->file  ));
    $self->build_children;
    return $self;
}

sub run_tests {

}

1;
