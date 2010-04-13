package Fennec::Workflow;
use strict;
use warnings;

use base 'Fennec::Base::Method';

require Fennec;

use Fennec::Util::Alias qw/
    Fennec::Runner
    Fennec::TestFile
    Fennec::TestSet
    Fennec::Output::Result
    Fennec::Output::Diag
/;

use Fennec::Util::Accessors;
use Try::Tiny;
use Carp;

use Time::HiRes       qw/time/;
use Benchmark         qw/timeit :hireswallclock/;
use Scalar::Util      qw/blessed/;
use List::Util        qw/shuffle/;
use Exporter::Declare qw/:extend/;

Accessors qw/ parent _testsets _workflows /;

our @BUILD_HOOKS;

sub alias       { current() }
sub has_current { 0 }
sub current     { confess "No current worflow" }
sub depth       { 0 }
sub proto       {( _testsets => [], _workflows => [] )}
sub build_hooks { @BUILD_HOOKS }

export 'import' => sub {
    my $class = shift;
    my $caller = caller;
    $class->export_to( $caller );
};

export build_hook => sub(&) {
    push @BUILD_HOOKS => @_;
};

export export => sub { goto &export };

sub import {
    my $class = shift;
    my $caller = caller;
    my ( $imports, $specs ) = $class->_import_args( @_ );

    return 1 unless( $specs->{subclass});

    $class->export_to( $caller, $specs->{prefix} || undef, @$imports );

    no strict 'refs';
    push @{ $caller . '::ISA' } => $class
        unless grep { $_ eq $class } @{ $caller . '::ISA' };
}

sub run_tests {
    my $self = shift;
        try {
            my @sets = $self->testsets;
            if ( Runner->search ) {
                @sets = $self->search_filter( Runner->search, \@sets );
            }

            @sets = shuffle @sets if $self->testfile->fennec_meta->random;
            @sets = sort { $a->name cmp $b->name } @sets
                if $self->testfile->fennec_meta->sort;

            my $benchmark = timeit( 1, sub {
                for my $set ( @sets ) {
                    $self->testfile->fennec_meta->threader->run(sub {
                        Runner->reset_benchmark;
                        $set->run()
                    });
                }
                $self->testfile->fennec_meta->threader->finish
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
    my @out;
    if ( $filter =~ m/^\d+$/ ) {
        @out = $self->filter_by_line_number( $filter, $tests )
    }
    else {
        @out = $self->filter_by_name( $filter, $tests );
    }
    return @out;
}

sub filter_by_line_number {
    my $self = shift;
    my ( $filter, $tests ) = @_;
    my %map;
    for my $item ( @$tests ) {
        my %seen;
        my @lines = grep { !$seen{$_}++ } $item->lines_for_filter;
        push @{ $map{$_}} => $item for @lines;
    }

    # 'B' returns the first line that has a statement within in the sub:
    # 1: sub x {
    # 2:  print 'x';
    # 3: }
    # B would give us line '2', so we shift everything up a line unless there
    # is already something for that line.
    for my $line ( keys %map ) {
        $map{($line - 1)} = delete $map{$line}
            unless $map{($line - 1)}
    }

    my ($idx) = grep { $_ <= $filter } sort { $b <=> $a } keys %map;
    return unless $idx;
    return @{ $map{ $idx }};
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
    confess 'xxx' unless blessed( $self );
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
    my %args = Fennec->test_class_args;
    my $constructor = delete $args{ constructor };
    $self->parent( $tclass->fennec_new(
        constructor => $constructor,
        meta => {
            workflow => $self,
            file => $self->file,
            %args,
        },
    ));
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
    if ( my $skip = $self->SUPER::skip( @_ )) {
        return $skip;
    }
    my $parent = $self->parent;
    $parent->isa( 'Fennec::TestFile' )
        ? $parent->fennec_meta->skip
        : $parent->skip;
}

sub todo {
    my $self = shift;
    if ( my $todo = $self->SUPER::todo( @_ )) {
        return $todo;
    }
    my $parent = $self->parent;
    $parent->isa( 'Fennec::TestFile' )
        ? $parent->fennec_meta->todo
        : $parent->todo;
}

sub run_method_as_current {
    my $self = shift;
    my ( $method, @args ) = @_;
    return $self->run_method_as_current_on( $method, $self, @args );
}

sub run_method_as_current_on {
    my $self = shift;
    croak( 'xxx' ) unless blessed( $self );
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
    croak( 'xxx' ) unless blessed( $self );
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
