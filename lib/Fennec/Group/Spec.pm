package Fennec::Group::Spec;
use strict;
use warnings;
use Carp;

use base 'Fennec::Group';

sub depends {[qw/
    Fennec::Group::Spec::BeforeEach
    Fennec::Group::Spec::BeforeAll
    Fennec::Group::Spec::AfterEach
    Fennec::Group::Spec::AfterAll
    Fennec::Group::Spec::Tests
/]}

sub function { 'describe' }

sub add_item {
}

sub tests {
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
