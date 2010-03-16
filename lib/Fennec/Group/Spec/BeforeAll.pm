package Fennec::Group::Spec::BeforeAll;
use strict;
use warnings;
use Carp;

use base 'Fennec::Group';

sub depends {[ 'Fennec::Group::Spec' ]}

sub function { 'before_all', 'subproto' => 1 }

sub add_item { croak 'Subgroups cannot be added to setups or teardowns' }

sub tests {}

1;
