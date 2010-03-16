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
