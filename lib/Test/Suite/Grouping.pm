package Test::Suite::Grouping;
use strict;
use warnings;

sub export_to {
    my $class = shift;
    my ( $package ) = @_;
    return 1 unless $package;

    {
        my $us = $class . '::';
        no strict 'refs';
        return grep { defined( *{$us . $_}{CODE} )} keys %$us;
    }
}

sub test_set {

}

sub test_case {

}

1;
