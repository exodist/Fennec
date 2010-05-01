package Fennec::TestFile::Meta;
use strict;
use warnings;

use Fennec::Util::Accessors;
use Try::Tiny;
use Carp;

use Fennec::Util::Alias qw/
    Fennec::Runner
/;

use Scalar::Util qw/blessed/;

our %MAP;

Accessors qw/ root_workflow workflow_stack threader todo skip file sort /;

sub set {
    my $class = shift;
    my ( $item, $meta ) = @_;
    $item = blessed( $item ) || $item;
    $MAP{ $item } = $meta;
}

sub get {
    my $class = shift;
    my ( $item ) = @_;
    $item = blessed( $item ) || $item;
    return $MAP{ $item };
}

sub test_classes {
    return keys %MAP;
}

sub new {
    my $class = shift;
    my %proto = @_;
    my ( $todo, $skip, $workflow_class, $file, $random, $sort )
        = @proto{qw/ todo skip root_workflow file random sort /};

    my $self = bless(
        {
            root_workflow => $workflow_class->new(
                $file,
                method => sub { 1 },
                file => $file,
            ),
            threader      => Parallel::Runner->new(
                $proto{ no_fork } ? 1 : Runner->parallel_tests,
                reap_callback => \&Fennec::Runner::_reap_callback,
            ),
            file           => $file,
            workflow_stack => [],
            skip           => $skip || undef,
            todo           => $todo || undef,
            defined( $random ) || $sort
                ? (
                    random => $random || 0,
                    sort   => $sort || undef,
                )
                : (),
        },
        $class
    );
    my $init = $class->can( 'init' ) || $class->can( 'initialize' );
    $self->$init( @_ ) if $init;
    return $self;
}

sub random {
    my $self = shift;
    ( $self->{ random }) = @_ if @_;
    return defined $self->{ random }
        ? $self->{ random }
        : Runner->random;
}

sub workflow {
    my $self = shift;
    return $self->workflow_stack->[-1] || $self->root_workflow;
}

sub push_workflow {
    my $self = shift;
    my ( $workflow ) = @_;
    push @{ $self->workflow_stack } => $workflow;
    return $self->depth;
}

sub depth {
    my $self = shift;
    return scalar @{ $self->workflow_stack };
}

sub pop_workflow {
    my $self = shift;
    my ( $depth ) = @_;
    croak "workflow pop at depth $depth, but current depth is " . $self->depth
        unless $depth == $self->depth;
    pop @{ $self->workflow_stack };
    return $self->depth;
}

sub name { shift->file }

1;

=head1 NAME

Fennec::TestFile::Meta - Meta information for L<Fennec::TestFile> objects

=head1 DESCRIPTION

This class stores meta information for L<Fennec::TestFile> objects. Fennec
needs various meta information when working with test files. Instead of adding
methods to TestFile that might interfer with a subclass, Fennec associates a
Meta object with a TestFile class.

=head1 CLASS METHODS

=over 4

=item $class->set( $test_file_class, $metaobj )

Associate a meta object with a test file class.

=item $metaobj = $class->get( $TestFileClass )

Get the meta object associated with a test file class.

=item my $metaobj = $class->new( %proto )

Create a new instance of a meta object.

    my $meta = $class->new(
        todo => $todo || undef,
        skip => $skip || undef,
        file => $testfile_obj,
        sort => $s_bool,
        random => $r_bool,
        workflow => $root_workflow,
    );

=back

=head1 OBJECT METHODS

=over 4

=item $random = $obj->random()

True if the testsets should be randomized

=item $filename = $obj->name()

Return the filename that defined the TestFile class.

=item $workflow = $obj->workflow()

Get the workflow at the top of the stack

=item $workflow = $obj->root_workflow()

Get the root workflow for the TestFile

=item $threader = $obj->threader()

Get the threader used by the runner to run tests in parallel.

=item $reason = $obj->todo()

Reason why the testfile should is todo (if it is)

=item $reason = $obj->skip()

Reason why the testfile should be skipped (if it should)

=item $testfile_obj = $obj->file()

Get the TestFile object.

=item $sort = $obj->sort()

True if the tests should be sorted instead of randomized.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
