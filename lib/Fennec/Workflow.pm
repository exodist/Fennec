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
    Fennec::Assert
/;

use Fennec::Util::Accessors;
use Try::Tiny;
use Carp;

use Time::HiRes       qw/time/;
use Scalar::Util      qw/blessed/;
use List::Util        qw/shuffle/;
use Exporter::Declare qw/:extend/;

Accessors qw/ parent _testsets _workflows built /;

our @BUILD_HOOKS;

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

export build_with => sub {
    my ( $name, $build ) = @_;
    my ($class) = caller;
    $build ||= $class;

    $class->export( $name, sub {
        caller->fennec_meta->workflow->add_item(
            $build->new( @_ )
        );
    });
};

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

sub run_build_hooks {
    my $self = shift;
    my $success = 1;
    try {
        $self->run_sub_as_current( $_, $self )
            for $self->build_hooks();
    }
    catch {
        $success = 0;
        Result->new(
            pass => 0,
            file => $self->file || "unknown file",
            name => "Build Hooks",
            stderr => [ $_ ],
        )->write;
    };
    return $success;
}

sub run_tests {
    my $self = shift;
    try {
        my @sets = $self->testsets;
        $_->observed( 1 ) for @sets;

        if ( Runner->search ) {
            @sets = $self->search_filter( Runner->search, \@sets );
        }

        @sets = shuffle @sets if $self->testfile->fennec_meta->random;
        @sets = sort { $a->name cmp $b->name } @sets
            if $self->testfile->fennec_meta->sort;

        my $start = time;
        for my $set ( @sets ) {
            $self->testfile->fennec_meta->threader->run(sub {
                Runner->reset_benchmark;
                $set->run()
            });
        }
        $self->testfile->fennec_meta->threader->finish;
        my $end = time;
        Result->pass_workflow( $self, [($end - $start)] );
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
    my ( $item ) = @_;
    my $type = blessed( $item );

    if ( $self->built ) {
        my %testcaller = Assert->test_caller;
        die "Attempt to add '$type("
            . ($item->can( 'name' ) ? $item->name : "unnamed" )
            . ")' to workflow '"
            . $self->name
            . "' after the workflow has already been built.\n"
            . "Did you try to define a workflow or testset inside a testset?\n"
            . "File: "
            . $testcaller{file}
            . "\nLine: "
            . $testcaller{line}
            . "\n"
    }

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
    croak( "Workflow '" . $self->name . "' already built" )
        if $self->built;

    if ( $self->skip ) {
        Result->skip_workflow( $self, $self->skip );
        return $self;
    }

    $self->run_method_as_current_on( $self->method, $self->testfile );
    $self->build_children;

    $self->built( 1 );
    return $self;
}

sub build_children {
    my $self = shift;
    $_->build for $self->workflows;
    return $self;
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
    my ( $method, $obj, @args ) = @_;
    return $self->run_as_current( sub {
        return $obj->$method( @args );
    });
}

sub run_sub_as_current {
    my $self = shift;
    my ( $sub, @args ) = @_;
    return $self->run_as_current( sub {
        return $sub->( @args );
    });
}

sub run_as_current {
    my $self = shift;
    my ( $sub ) = @_;

    my $obj = $self->testfile;
    my $depth = $obj->fennec_meta->push_workflow( $self );
    my $want = wantarray;
    my ( $out, @out );
    try {
        if ( $want ) {
            @out = $sub->();
        }
        else {
            $out = $sub->();
        }
    }
    catch {
        eval { $obj->fennec_meta->pop_workflow( $depth ) };
        die( $_ );
    };
    $obj->fennec_meta->pop_workflow( $depth );
    return $want ? @out : $out;
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
