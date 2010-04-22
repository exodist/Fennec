#!/usr/bin/perl
use strict;
use warnings;

use Cwd;

use Fennec::Util::Alias qw/
    Fennec::Runner
/;

'Fennec::Runner'->init(
    parallel_files => 2,
    parallel_tests => 2,
    cull_delay => .01,
    handlers => [qw/ TAP /],
    random => 1,
    Collector => 'Files',
    ignore => undef,
    filetypes => [qw/ Module /],
    default_asserts => [qw/Core/],
    default_workflows => [qw/Spec Case/],
);

Runner()->run_tests;
