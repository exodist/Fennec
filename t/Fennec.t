#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Finder match => qr/\.ft$/;
use Test::More;

is_deeply(
    [sort map { m{([^/]+\.ft)$}; $1 } @{Fennec::Finder->new->test_classes}],
    [
        qw(
            CantFindLayer.ft
            Case-Scoping.ft
            Mock.ft
            Workflow_Fennec.ft
            hash_warning.ft
            import_skip.ft
            inner_todo.ft
            order.ft
            procs.ft
            ),
    ],
    "Found all test files"
);

run();

die "Did not run all tests"
    unless Fennec::Finder->new->collector->test_count > 10;

1;
