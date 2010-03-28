package Fennec::Workflow;
use strict;
use warnings;

use base 'Fennec::Base::Method';

use Fennec::Runner;
use Fennec::Util::Accessors;
use Fennec::TestFile;
use Fennec::TestSet;
use Fennec::Output::Result;
use Try::Tiny;
use Carp;

use Time::HiRes qw/time/;
use Benchmark qw/timeit :hireswallclock/;
use Scalar::Util qw/blessed/;
use List::Util   qw/shuffle/;

Accessors qw/ parent _testsets _workflows /;

sub function    {}
sub depends     {[ 'Fennec::TestSet' ]}
sub alias       { shift->current }
sub has_current { 0 }
sub current     { confess "No current worflow" }
sub depth       { 0 }
sub proto       {( _testsets => [], _workflows => [] )}

sub run_tests {
    my $self = shift;
        try {
            my @sets = $self->testsets;
            if ( Runner->search ) {
                @sets = $self->search_filter( Runner->search, \@sets );
            }

            # Even if we are searching we might have multiple tests, randomize
            # them.
            @sets = shuffle @sets if $self->testfile->random;

            my $benchmark = timeit( 1, sub {
                for my $set ( @sets ) {
                    $self->testfile->threader->run(sub {
                        $set->run()
                    });
                }
                $self->testfile->threader->finish
            });
            Result->pass_workflow( $self, $benchmark );
        }
        catch {
            Result->fail_workflow( $self, $_ );
        };
}

sub search_filter {
    my $self = shift;
    my ( $filter, $tests ) = @_;
    return $self->filter_by_line_number( $filter, $tests )
        if $filter =~ m/^\d+$/;
    return $self->filter_by_name( $filter, $tests );
}

sub filter_by_line_number {
    my $self = shift;
    my ( $filter, $tests ) = @_;
    my %map;
    for my $item ( @$tests ) {
        push @{ $map{ $item->line }} => $item;
    }
    # First number at or after.
    my ($correct) = grep { $_ >= $filter } sort keys %map;
    return unless $correct;
    return @{ $map{ $correct }};
}

sub filter_by_name {
    my $self = shift;
    my ( $filter, $tests ) = @_;
    return grep { $_->part_of( $filter )} @$tests;
}

sub testsets {
    my $self = shift;
    my @tests = @{ $self->_testsets };
    push @tests => $_->testsets for $self->workflows;
    return @tests;
}

sub workflows {
    my $self = shift;
    return @{ $self->_workflows };
}

sub add_item {
    my $self = shift;
    my ( $item ) = @_;
    my $type = blessed( $item );
    croak( "Item must be a blessed Workflow or Testset object" )
        unless $type and $item->isa( 'Fennec::Base::Method' );

    if ($item->isa('Fennec::TestSet')) {
        push @{ $self->_testsets } => $item;
        $item->workflow( $self );
    }
    elsif($item->isa('Fennec::Workflow')) {
        push @{ $self->_workflows } => $item;
        $item->parent( $self );
    }
    else { confess("Not sure what to do with $type") }

    return $self;
}

sub build {
    my $self = shift;
    if ( $self->skip ) {
        Result->skip_workflow( $self, $self->skip );
        return $self;
    }
    $self->run_method_as_current_on( $self->method, $self->testfile );
    $self->build_children;
    return $self;
}

sub _build_as_root {
    my $self = shift;
    my $tclass = $self->run_method_as_current( $self->method );
    $self->parent( $tclass->new( workflow => $self, file => $self->file  ));
    return $self;
}

sub build_children {
    my $self = shift;
    $_->build for $self->workflows;
    return $self;
}

sub current_add_item {
    shift->current->add_item( @_ );
}

sub add_items {
    my $class_or_self = shift;
    $class_or_self->add_item( $_ ) for @_;
}

sub testfile {
    my $self = shift;

    unless ( $self->{ test }) {
        my $parent = $self->parent;
        $self->{ test } = $parent->isa( TestFile )
            ? $parent
            : $parent->testfile;
    }

    return $self->{ test };
}

sub skip {
    my $self = shift;
    return $self->SUPER::skip( @_ )
        || $self->parent->skip;
}

sub todo {
    my $self = shift;
    return $self->SUPER::todo()
        || $self->parent->todo;
}

sub run_method_as_current {
    my $self = shift;
    my ( $method, @args ) = @_;
    return $self->run_method_as_current_on( $method, $self, @args );
}

sub run_method_as_current_on {
    my $self = shift;
    my ( $method, $obj, @args ) = @_;
    my $depth = $self->depth + 1;

    no warnings 'redefine';
    local *has_current = sub { 1 };
    local *current = sub { $self };
    local *depth = sub { $depth };
    return $obj->$method( @args );
}

sub run_sub_as_current {
    my $self = shift;
    my ( $sub, @args ) = @_;
    my $depth = $self->depth + 1;

    no warnings 'redefine';
    local *has_current = sub { 1 };
    local *current = sub { $self };
    local *depth = sub { $depth };
    return $sub->( @args );
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
