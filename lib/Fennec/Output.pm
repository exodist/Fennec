package Fennec::Output;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %proto = @_;
    my $self = bless( \%proto, $class );
    $self->init if $self->can( 'init' );
    return $self;
}

sub result {
    my $class = shift;
    die( "$class does not implement result()" );
}

sub diag {
    my $class = shift;
    die( "$class does not implement diag()" );
}

sub finish {1}

1;
