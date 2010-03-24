package Fennec::Workflow::Root;
use strict;
use warnings;

use base 'Fennec::Workflow';

use Fennec::Output::Result;
use Fennec::Runner;
use Carp;
use Try::Tiny;
use Time::HiRes qw/time/;
use Benchmark qw/timeit :hireswallclock/;

use List::Util qw/shuffle/;

sub depends {[ 'Fennec::Workflow::Tests' ]}

sub build {
    my $self = shift;
    my $tclass = $self->run_method_as_current( $self->method );
    $self->parent( $tclass->new( workflow => $self, file => $self->file  ));
    return $self;
}

sub run_tests {
    my $self = shift;
    my @tests = $self->_tests;
    $self->run_test_list ( \@tests );
    $self->test->threader->finish;
}

sub run_test_list {
    my $self = shift;
    my ( $tests ) = @_;
    my $search = Runner->search;
    @$tests = shuffle @$tests if $self->test->random;
    for my $test ( @$tests ) {
        if ( ref $test eq 'HASH' ) {
            try {
                $self->run_subworkflow_list( $test );
            }
            catch {
                Result->fail_workflow( $test->{ workflow }, $_ );
            };
        }
        else {
            next if $search && !$test->part_of( $search );
            $self->test->threader->run(sub {
                try {
                    my $benchmark = timeit( 1, sub {
                        $test->run_on( $self->test );
                    });
                    Result->pass_workflow( $test, benchmark => $benchmark );
                }
                catch {
                    Result->fail_workflow( $test->{ workflow }, $_ );
                };
            });
        }
    }
}

sub run_subworkflow_list {
    my $self = shift;
    my ( $item ) = @_;
    my $before = delete $item->{ before } || [];
    my $after = delete $item->{ after } || [];
    my $tests = delete $item->{ tests } || croak( "No tests" );

    $_->run_on( $self->test ) for @$before;
    $self->run_test_list( $tests );
    $_->run_on( $self->test ) for @$after;
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
