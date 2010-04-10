package Fennec::Debug;
use strict;
use warnings;
use Carp qw/cluck/;

sub debug {
    my $class = shift;
    my @messages = @_;
    cluck @messages;
    print $class->collector_state;
    print $class->runner_state;
}

sub collector_state {
    "Not ready";
}

sub runner_state {
    "Not ready";
}

1;
