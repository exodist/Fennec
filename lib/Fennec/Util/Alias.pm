package Fennec::Util::Alias;
use strict;
use warnings;
use Carp;

sub import {
    my $class = shift;
    my $caller = caller;

    for my $import ( @_ ) {
        eval "require $import; 1" || croak( $@ );
        my $name = $import;
        $name =~ s/.*\::([^:]+)$/$1/;
        no strict 'refs';
        *{ $caller . '::' . $name } = sub {
            my $alias = $import->can( 'alias' );
            return $import unless $alias;

            my @caller = caller;
            return $import->alias( \@caller, @_ );
        };
    }
}

1;
