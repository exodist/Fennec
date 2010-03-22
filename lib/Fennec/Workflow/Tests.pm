package Fennec::Workflow::Tests;
use strict;
use warnings;
use Carp;

use base 'Fennec::Workflow';

sub _tests { }
sub tests { }
sub function { 'tests' }

sub add_item { croak 'Child workflows cannot be added to test workflows' }

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
