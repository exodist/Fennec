#!/usr/bin/perl
use strict;
use warnings;

use Cwd;

use Fennec::Util::Alias qw/
    Fennec::Runner
/;

'Fennec::Runner'->init(
    p_files => 2,
    p_tests => 2,
    handlers => [qw/ TAP /],
    random => 1,
    Collector => 'Files',
    ignore => undef,
    filetypes => [qw/ Module /],
    default_asserts => [qw/Core Interceptor/],
    default_workflows => [],
    $ENV{ FENNEC_FILE } ? ( files => [ cwd() . '/' . $ENV{ FENNEC_FILE }]) : (),
    $ENV{ FENNEC_ITEM } ? ( search => $ENV{ FENNEC_ITEM }) : (),
);

Runner()->start;
