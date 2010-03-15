package Fennec::Group;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Runner;

sub current { Runner->current->stack->peek->group }

1;
