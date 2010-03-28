package Fennec::Workflow::Methods;
use strict;
use warnings;

use base 'Fennec::Workflow';

use Fennec::Util;
use Scalar::Util qw/blessed/;

sub new {
    my $class = shift;
    return bless({ method => sub {1}, children => [] }, $class );
}

sub function { 'use_test_methods' }

sub add_item { croak 'Child workflows cannot be added to the Methods workflow' }

sub tests {
    my $self = shift;
    my $testfile = $self->testfile;
    my $tclass = blessed( $testfile );
    return {
        before => [ sort Util->package_subs( $tclass, qr/^setup_/i    )],
        tests  => [ sort Util->package_subs( $tclass, qr/^test_/i     )],
        after  => [ sort Util->package_subs( $tclass, qr/^teardown_/i )],
    };
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
