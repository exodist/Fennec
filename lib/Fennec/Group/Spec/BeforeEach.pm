package Fennec::Group::Spec::BeforeEach;
use strict;
use warnings;
use Carp;

use base 'Fennec::Group';

sub depends {[ 'Fennec::Group::Spec' ]}

sub function { 'before_each', 'subproto' => 1 }

sub add_item { croak 'Subgroups cannot be added to setups or teardowns' }

sub tests {}

1;
