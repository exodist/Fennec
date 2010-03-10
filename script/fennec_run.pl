#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Runner;

##
## Configure your runner with this hash. Only confure machine and platform
## agnostic options here. This will be used by anyone who runs your tests.
######################################################

our %NEWARGS = (
    file_types => [ 'TDir', 'Offset' ],
    random => 1,

    # This is necessary for specifying case/set/file
    argv => $ENV{FENNEC_ARGV}
        ? [ split(/\s+/, $ENV{FENNEC_ARGV} )]
        : (@ARGV ? \@ARGV : undef),
);

Fennec::Runner->new(%NEWARGS)->run;

1;
