package Fennec;
use strict;
use warnings;

use Carp;
use Fennec::Util::TBOverride;
use Fennec::Util::PackageFinder;

use Fennec::Util::Alias qw/
    Fennec::Runner
    Fennec::TestFile
    Fennec::Assert
    Fennec::TestFile::Meta
/;

our $VERSION = "0.018";
our @META_DATA = qw/todo skip random sort no_fork/;

sub import {
    my $class = shift;
    my %proto = @_;
    $proto{ caller } ||= [ caller ];
    $proto{ meta } = { map {( $_ => delete $proto{$_} || undef)} @META_DATA };
    delete $proto{ standalone };

    my $fennec = $class->new( %proto );
    $fennec->subclass;
    $fennec->init_meta;
    $fennec->export_tools;
    $fennec->export_workflows;
    $fennec->export_asserts;

    1;
}

sub new {
    my $class = shift;
    my %proto = @_;
    my $self = bless( \%proto, $class );
    $self->sanity;
    return $self;
}

sub sanity {
    my $self = shift;
    if ( Meta->get( $self->test_class )) {
        croak "Meta info for '"
           . $self->test_class
           . "' already initialized, did you 'use Fennec' twice?";
    }

    croak "Test runner not found"
        unless Runner;
    croak( "You must put your tests into a package, not main" )
        if $self->test_class eq 'main';
}

sub test_class {
    my $self = shift;
    return $self->{caller}->[0];
}

sub test_file {
    my $self = shift;
    return $self->{caller}->[1];
}

sub imported_line {
    my $self = shift;
    return $self->{caller}->[2];
}

sub workflows {
    my $self = shift;
    return $self->{workflows} || Runner->default_workflows;
}

sub asserts {
    my $self = shift;
    return $self->{asserts} || Runner->default_asserts;
}

sub root_workflow {
    my $self = shift;
    return $self->{root_workflow} || Runner->root_workflow_class;
}

sub subclass {
    my $self = shift;
    return if $self->test_class->isa( TestFile );
    no strict 'refs';
    push @{ $self->test_class . '::ISA' } => TestFile;
}

sub init_meta {
    my $self = shift;

    my $meta = Meta->new(
        %{ $self->{ meta }},
        file          => $self->test_file,
        root_workflow => $self->root_workflow,
    );
    Meta->set( $self->test_class, $meta );
}

sub export_tools {
    my $self = shift;
    _export_package_to( 'Fennec::TestSet', $self->test_class );

    no strict 'refs';
    *{ $self->test_class . '::done_testing' } = \&_done_testing;
    *{ $self->test_class . '::use_or_skip' } = \&_use_or_skip;
    *{ $self->test_class . '::require_or_skip' } = \&_require_or_skip;
}

sub export_workflows {
    my $self = shift;
    _export_package_to( load_package( $_, 'Fennec::Workflow' ), $self->test_class )
        for @{ $self->workflows };
}

sub export_asserts {
    my $self = shift;
    _export_package_to( load_package( $_, 'Fennec::Assert' ), $self->test_class )
        for @{ $self->asserts };
}

sub _export_package_to {
    my ( $from, $to ) = @_;
    die( $@ ) unless eval "require $from; 1";
    $from->export_to( $to );
}

sub _done_testing {
    carp "calling done_testing() is only required for Fennec::Standalone tests"
};

sub _use_or_skip(*;@) {
    my ( $package, @params ) = @_;
    my $caller = caller;
    my $eval = "package $caller; use $package"
    . (@params ? (
        @params > 1
            ? ' @params'
            : ($params[0] =~ m/^[0-9\-\.\e]+$/
                ? " $params[0]"
                : " '$params[0]'"
              )
      ) : '')
    . "; 1";
    my $have = eval $eval;
    die "SKIP: $package is not installed or insufficient version: $@" unless $have;
};

sub _require_or_skip(*) {
    my ( $package ) = @_;
    my $have = eval "require $package; 1";
    die "SKIP: $package is not installed\n" unless $have;
};

1;

=pod

=head1 NAME

Fennec - Framework upon which intercompatible testing solutions can be built.

=head1 DESCRIPTION

L<Fennec> provides a solid base that is highly extendable. It allows for the
writing of custom nestable workflows (like RSPEC), Custom Asserts (like
L<Test::Exception>), Custom output handlers (Alternatives to TAP), Custom file
types, and custom result passing (collectors). In L<Fennec> all test files are
objects. L<Fennec> also solves the forking problem, thats it, forking just
plain works.

=head1 EARLY VERSION WARNING

L<Fennec> is still under active development, many features are untested or even
unimplemented. Please give it a try and report any bugs or suggestions.

=head1 FEATURES

Fennec offers the following features, among others.

=over 4

=item No large dependancy chains

=item No method attributes

=item No use of END blocks

=item No Devel::Declare magic

=item No use of Sub::Uplevel

=item No source filters

=item Large library of core test functions

=item Plays nicely with L<Test::Builder> tools

=item Better diagnostics

=item Highly Extendable

=item Lite benchmarking for free

=item Works with prove

=item Full-Suite management

=item Standalone test support

=item Support for SPEC and other test workflows

=item Forking works

=item Run only specific test sets within test files (for development)

=item Intercept or hook into most steps or components by design

=back

=head1 DOCUMENTATION

=over 4

=item QUICK START

L<Fennec::Manual::Quickstart> - Drop Fennec standalone tests into an existing
suite.

=item FENNEC BASED TEST SUITE

L<Fennec::Manual::TestSuite> - How to create a Fennec based test suite.

=item MISSION

L<Fennec::Manual::Mission> - Why does Fennec exist?

=item MANUAL

L<Fennec::Manual> - Advanced usage and extending Fennec.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
