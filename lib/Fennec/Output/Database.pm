package Fennec::Output::Database;
use strict;
use warnings;

use base 'Fennec::Output';

sub init {
    my $self = shift;
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;
}

sub diag {
    my $self = shift;
}

sub finish {
    my $self = shift;
}


