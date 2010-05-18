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

our $VERSION = "0.021";
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
    $self->_sanity;
    return $self;
}

sub _sanity {
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

Fennec - Full Featured Testing Toolbox And Development Kit

=head1 DESCRIPTION

Fennec is a full featured testing toolbox. Fennec provides all the tools your
used to, but in a framework that allows for greater interopability of third
party tools. Along with the typical set of tools, Fennec addresses many common
problems, complaints, and wish list items.

In addition to the provided tools, Fennec provides a solid framework and highly
extendable API. Using Fennec you can write custom workflows, assertions,
testers, and output plugins. You can even define custom file types and file
loaders.

=head1 SYNOPSIS

    package TEST::MyModule;
    use strict;
    use warnings;
    use Fennec::Standalone;

    use_or_skip 'Dependancy::Module';

    use_ok 'MyModule';

    tests simple {
        can_ok( 'MyModule', 'new' );
        isa_ok( MyModule->new(), 'MyModule' );
        dies_ok { MyModule->Thing_that_dies } "thing dies";
        warning_like { MyModule->Thing_that_warns } qr/.../, "thing warns";

        is_deeply( ... );
        ...
    }

    describe 'RSPEC Tests' {
        # Automatically get $self
        before_each { $self->do_something }
        after_each { $self->do_something_else }

        it test_one {
            ok( 1, "1 is true!" )
        }

        describe { ... };
    }

    cases some_primes {
        my $var;
        case two { $var = 2 };
        case three { $var = 3 };

        tests is_prime {
            ok( is_prime($var), "var is prime" )
        };
    }

    1;

=head1 FURTHER READING

=over 4

=item L<Fennec::Manual::Tests>

Primer on Fennec's core tools

=item L<Fennec::Manual::TestSuite>

Writing standalone tests that exist isolated in .t files.

=item L<Fennec::Manual::Standalone>

Using Fennec as a runner to better manage your test suite.

=back

=head1 FEATURES

Fennec offers the following features, among others.

=over 4

=item Declarative syntax

Fennec uses L<Devel::Declare> via L<Exporter::Declare> to provide a nice, clean
declarative syntax.

=item Large library of core test functions

L<Fennec::Assert::Core>

=item Plays nicely with L<Test::Builder> tools

L<Fennec::Manual::TBAssertions>

=item Better diagnostics

No STDERR and STDOUT disconnect between a failure and its output. If a tool
does not provide helpful output Fennec tries to give you some anyway.

=item Highly Extendable

Thats the goal

=item Lite benchmarking for free

Time between results in each process is timed.

=item Works with prove

t/Fennec.t as a runner, or L<Fennec::Standalone>

=item Full-Suite management

L<Fennec::Manual::TestSuite>

=item Standalone test support

L<Fennec::Manual::Standalone>

=item Support for SPEC and other test workflows

L<Fennec::Workflow::SPEC> and L<Fennec::Workflow::Case>

=item Forking works

Results are process-aware, no mangled test numbers.

=item Run only specific test sets within test files (for development)

Don't run an entire test file to debug a single section

=item Intercept or hook into most steps or components by design

No limits.

=item No large dependancy chains

Mostly core dependancies, only a couple cpan modules.

=item No attributes

By attrivutes we mean: L<http://perldoc.perl.org/attributes.html>

=item No use of END blocks

Thar be dragons.

=item No use of Sub::Uplevel

Known to cause problems with Carp, L<Test::Exception>, and others.

=item No source filters

Never.

=back

=head1 FENNEC DEVELOPER DOCUMENTATION

=over 4

=item MISSION

L<Fennec::Manual::Mission> - Why does Fennec exist?

=item MANUAL

L<Fennec::Manual> - Advanced usage and extending Fennec.

=back

=head2 MODULE API

B<This section only covers the API for Fennec.pm. See L<Fennec::Manual> and other
documentation for other module API's.>

B<This section is not for those who simply wish to write tests, this is for
people who want to extend Fennec.>

=head3 Class methods

=over 4

=item import( %proto )

    use Fennec %proto;

Called when you use the Fennec module. %proto is key/value pairs for
configuration and/or test class meta data. Meta data keys may be mixed in or
placed in a hashref under the 'meta' key.

=item my $obj = $class->new( %proto )

Create a new instance. %proto can be all the same key/value pairs as import(),
except that the meta data must be in a hashref under the 'meta' key. You must
also specify a 'caller' key with an arrayref containing a package name,
filename, and line number for the test file.

=back

=head3 Object methods

When you use Fennec, it will create an object internally to do some
initialization and exporting. These are it's methods.

=over 4

=item test_class()

Returns the test class. This will either be determined by import() or provided
to import/new via the first element of the arrayref provided under the 'caller'
key.

=item test_file()

Returns the test filename. This will either be determined by import() or provided
to import/new via the second element of the arrayref provided under the
'caller' key.

=item imported_line()

Returns the line number where fennec was used. This will either be determined
by import() or provided to import/new via the third element of the arrayref
provided under the 'caller' key.

=item workflows()

Returns an arrayref containing the workflow names provided at import, or if
none were provided, then the defaults will be provided.

=item asserts()

Returns an arrayref containing the assert names provided at import, or if
none were provided, then the defaults will be provided.

=item root_workflow()

Returns the classname of the root workflow that will be used.

=item subclass()

Modifies the test classes @ISA array to make it a subclass of
L<Fennec::TestFile>

=item init_meta()

Initializes the meta object for the test class.

=item export_tools()

Export the basic tools to the test class

=item export_workflows()

Export the desired workflows to the test class

=item export_asserts()

Export the desired asserts to the test class

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
