package Fennec::Base;
use strict;
use warnings;

sub import {
    my $class = shift;
    my $caller = caller;

    my $name = $class;
    $name =~ s/^.*::([^:]+)$/$1/;

    my $sub = $class->can( 'alias' )
        ? sub {
            my @caller = caller;
            $class->alias( \@caller, @_ );
        }
        : sub { $class };

    no strict 'refs';
    *{ $caller . '::' . $name } = $sub;
}

1;
