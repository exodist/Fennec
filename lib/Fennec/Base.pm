package Fennec::Base;
use strict;
use warnings;

sub import {
    my $class = shift;
    my $caller = caller;

    my $name = $class;
    $name =~ s/^.*::([^:]+)$/$1/;

    no strict 'refs';
    *{ $caller . '::' . $name } = sub {
        my $alias = $class->can( 'alias' );
        return $class unless $alias;

        my @caller = caller;
        return $class->alias( \@caller, @_ );
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
