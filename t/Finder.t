#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Finder;
use Test::More;
use Data::Dumper;

is_deeply(
    [sort map { m{^.*/([^/]+$)}; $1 } @{Fennec::Finder->new->test_files}],
    [
        sort qw{
            CantFindLayer.ft
            Case-Scoping.ft
            FinderTest.pm
            Mock.ft
            RunSpecific.ft
            Todo.ft
            WorkflowTest.pm
            Workflow_Fennec.ft
            hash_warning.ft
            import_skip.ft
            inner_todo.ft
            order.ft
            procs.ft
            },
    ],
    "Found all test files"
) || print STDERR Dumper( Fennec::Finder->new->test_files );

run(
    sub {
        my $runner = Fennec::Runner->new();
        my $want   = 30;
        my $got    = $runner->collector->test_count;
        return if $runner->collector->ok( $got > $want, "Got expected test count" );
        $runner->collector->diag("Got:  $got\nWant: $want");
    },
);

1;
