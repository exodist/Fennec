package Test::Suite::Grouping;
use strict;
use warnings;
use Carp;

sub export_to {
    my $class = shift;
    my ( $package ) = @_;
    return 1 unless $package;

    {
        my $us = $class . '::';
        no strict 'refs';
        my @subs = grep { defined( *{$us . $_}{CODE} )} keys %$us;
        for my $sub ( @subs ) {
            *{ $package . '::' . $sub } = \&$sub;
        }
    }
}

sub test_set {
    my $name = shift;
    croak( "You must provide a set name, and it must not be a reference" )
        if !$name || ref $name;

    my $code = shift if @_ == 1;
    my %proto = ( method => $code, @_ );
    my ( $package ) = caller;

    $package->add_set( $name, %proto );
}

sub test_case {
    my $name = shift;
    croak( "You must provide a case name, and it must not be a reference" )
        if !$name || ref $name;

    my $code = shift if @_ == 1;
    my %proto = ( method => $code, @_ );
    my ( $package ) = caller;

    $package->add_case( $name, %proto );
}

1;
