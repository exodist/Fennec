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
