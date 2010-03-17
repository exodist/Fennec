package Fennec::Group::Methods;
use strict;
use warnings;

use base 'Fennec::Group';

use Fennec::Util;

sub new {
    my $class = shift;
    return bless({ method => sub {1}, children => [] }, $class );
}

sub function { 'use_test_methods' }

sub add_item { croak 'Subgroups cannot be added to the Methods group' }

sub tests {
    my $self = shift;
    my $test = $self->test;
    my $tclass = blessed( $test );
    return {
        before => [ sort Util->package_subs( $tclass, qr/^setup_/i    )],
        tests  => [ sort Util->package_subs( $tclass, qr/^test_/i     )],
        after  => [ sort Util->package_subs( $tclass, qr/^teardown_/i )],
    };
}

1;
