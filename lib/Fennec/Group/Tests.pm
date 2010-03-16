package Fennec::Group::Tests;
use strict;
use warnings;
use Carp;

use base 'Fennec::Group';

sub function { 'tests' }

sub add_item { croak 'Subgroups cannot be added to test groups' }

sub tests { }

1;
