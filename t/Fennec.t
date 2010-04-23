#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Util::Alias qw/
    Fennec::Runner
/;

'Fennec::Runner'->init(
    collector => 'Files',
    cull_delay => .01,
    default_asserts => [qw/Core Interceptor/],
    default_workflows => [qw/Spec Case Methods/],
    filetypes => [qw/ Module /],
    handlers => [qw/ TAP /],
    ignore => undef,
    parallel_files => 2,
    parallel_tests => 2,
    random => 1,
);

Runner()->run_tests;
