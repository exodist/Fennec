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

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
