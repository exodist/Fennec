#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Runner;

##
## Configure your runner with this hash. Only confure machine and platform
## agnostic options here. This will be used by anyone who runs your tests.
######################################################

our %NEWARGS = (
    file_types => [ 'TDir' ],
    ignore => [ qr{fakeroots} ],
    random => 1,
);

######################################################
## You shouldn't need to change anything below this ##
######################################################
our $RUNNER;
{
    no warnings 'once';
    $RUNNER = defined &Fennec::Prover::new
        ? Fennec::Prover->new(%NEWARGS)
        : Fennec::Runner->new(%NEWARGS);
}

$RUNNER->run;
