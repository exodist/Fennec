#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Runner;
'Fennec::Runner'->init(
    p_files => 2,
    p_tests => 2,
    handlers => [qw/ TAP /],
    random => 1,
    Collector => 'Files',
    ignore => undef,
    filetypes => [qw/ Module /],
);

Runner->start;
