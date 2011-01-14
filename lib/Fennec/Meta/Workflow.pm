package Fennec::Meta::Workflow;
use strict;
use warnings;

use base 'Fennec::Meta';

sub new {
    my $class = shift;
    return bless( {@_}, $class );
}

1
