#!/usr/bin/perl
use strict;
use warnings;

use Fennec;

my $parent_pid = $$;

describe set => (
    todo => "around_all is broken",
    code => sub {
        my $pid;
        my $count = 0;
        around_all foo => sub {
            my $self = shift;
            my ($run) = @_;
            $count++;
            $pid = $$;

            print( "# Ran\n" );

            $run->();
        };

        for my $i ( 1 .. 10 ) {
            tests $i => sub {
                is( $count, 1, "ran once" );
                is( $pid, $parent_pid, "ran in parent" );
            };
        }
    },
);

done_testing;
