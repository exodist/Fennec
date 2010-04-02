package Fennec::Workflow::Methods;
use strict;
use warnings;

use base 'Fennec::Workflow';

use Fennec::Util;
use Scalar::Util qw/blessed/;
use Fennec::Runner;
use Fennec::Workflow;
use Fennec::TestSet::SubSet;
use Carp;

sub new {
    my $class = shift;
    return bless({ method => sub {1}, children => [] }, $class );
}

#sub function { 'use_test_methods' }
sub build_hook {
    my $class = shift;
    Runner->pre_tests_hook( sub {
        Workflow->add_item( $class->new );
    });
}

sub add_item { croak 'Child workflows cannot be added to the Methods workflow' }

sub testsets {
    my $self = shift;
    my $testfile = $self->testfile;
    my $tclass = blessed( $testfile );
    my $subset = SubSet->new(
        name => 'Test Methods',
        workflow  => $self,
    );
    $subset->add_setup( @$_ )
        for sort { $a->[0] cmp $b->[0] }
            Fennec::Util->package_sub_map( $tclass, qr/^setup/i );

    $subset->add_testset( @$_ )
        for Fennec::Util->package_sub_map( $tclass, qr/^test_/i );

    $subset->add_teardown( @$_ )
        for sort { $a->[0] cmp $b->[0] }
            Fennec::Util->package_sub_map( $tclass, qr/^teardown/i );

    return $subset;
}

sub build_children {}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
