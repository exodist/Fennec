package Fennec::Group::Case;
use strict;
use warnings;
use Carp;

use base 'Fennec::Group';

sub depends {[ 'Case::Set' ]}

sub function { 'test_case' }

sub add_item { croak 'Subgroups cannot be added to cases' }

sub tests {
    #TODO - Build tests for each set
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
