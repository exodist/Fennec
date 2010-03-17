package Fennec::Group::Root;
use strict;
use warnings;
use Carp;

use base 'Fennec::Group';

use Fennec::Result;

use List::Util qw/shuffle/;

sub depends {[ 'Fennec::Group::Tests' ]}

sub build {
    my $self = shift;
    my $tclass = $self->run_method_as_current( $self->method );
    $self->parent( $tclass->new( group => $self, file => $self->file  ));
    return $self;
}

sub run_tests {
    my $self = shift;
    my @tests = $self->_tests;
    $self->run_test_list ( \@tests )
}

sub run_test_list {
    my $self = shift;
    my ( $tests ) = @_;
    @$tests = shuffle @$tests if $self->test->random;
    for my $test ( @$tests ) {
        if ( ref $test eq 'HASH' ) {
            try {
                $self->run_subgroup_list( $test );
            }
            catch {
                Result->fail_item( $test->{ group }, $_ );
            };
        }
        else {
            $self->test->threader->thread(sub {
                try {
                    $test->run_on( $self->test );
                }
                catch {
                    Result->fail_item( $test->{ group }, $_ );
                };
            });
        }
    }
}

sub run_subgroup_list {
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
