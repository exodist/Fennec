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
    Devel::Declare::Interface
/;

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
    $fennec->load_extra;

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
        stash         => {},
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
    *{ $self->test_class . '::M' } = \&_meta;
    *{ $self->test_class . '::S' } = \&_stash;
    Interface->enhance( $self->test_class, $_, 'begin' ) for qw/use_or_skip require_or_skip/;
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

sub load_extra {
    my $self = shift;
    my $into = $self->test_class;
    for my $set ( @{ Runner->load } ) {
        my ( $package, @args ) = @$set;
        eval "package $into; use $package \@args; 1"
            || die( $@ );
    }
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

sub _meta { caller()->fennec_meta() }

sub _stash {
    my $class = caller();
    my $meta = $class->fennec_meta();
    my $stash = $meta->stash;

    $stash ||= $meta->stash( {} );

    if (@_ == 1) {
        if ( my $ref = ref $_[0] ) {
            croak(
                "S() takes a hashref, a key name, or key value pairs.",
                "S() does not take a $ref."
            ) unless $ref eq 'HASH';
            return $meta->stash( $_[0] )
        }
        return $stash->{ $_[0] };
    }

    %$stash = ( %$stash, @_ );

    return wantarray ? %$stash : $stash;
}

1;

=pod

=head1 NAME

Fennec - Workflow based testing framework for Perl.

=head1 DESCRIPTION

Fennec is a workflow based testing framework for Perl. It is designed to be
easy to use, easy to extend, and to provide an incredible array of tools while
staying out of your way. Fennec provides everything your used to in Perl
testing framework along with enhancements inspired from other frameworks.

Fennec works just like traiditional L<Test::Builder> tools in that it allows
you to write script style tests. Fennec takes this a step further by
introducing behavior driven development with the concepts of test groups and
workflows. Fennec also requires that each test file define a class which Fennec
will instantiate.

Please see these docs for additional details:

=over 2

=item L<Fennec::Manual::Quickstart>

=item L<Fennec::Manual::User>

=back

=head1 SYNOPSIS

t/MyModule.t:

    package TEST::MyModule;
    use strict;
    use warnings;
    use Fennec::Standalone;

    use_or_skip 'Dependancy::Module';

    use_ok 'MyModule';

    # Put the name of the module we are testing in the stash (not required, but
    # good practice for plugin use.)
    S( testing => 'MyModule' );

    tests simple {
        can_ok( S('testing'), 'new' );
        isa_ok( S('testing')->new(), s('testing' ));
        dies_ok { S('testing')->Thing_that_dies } "thing dies";
        warning_like { S('testing')->Thing_that_warns } qr/.../, "thing warns";

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

        describe nested { ... };
    }

    cases some_primes {
        my $var;
        case two { $var = 2 }
        case three { $var = 3 }

        tests is_prime {
            ok( is_prime($var), "var is prime" )
        }
    }

    done_testing;

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back

=head1 FEATURES

Fennec offers the following features, among others.

=over 4

=item Declarative syntax

=item Large library of core assert functions

=item Plays nicely with L<Test::Builder> tools

=item Better diagnostics

=item Highly Extendable

=item Works with prove

=item Full-Suite management

=item Standalone test support

=item Support for SPEC and other test workflows

=item Forking just works

=item Run only specific test sets within test files (for development)

=item Intercept or hook into most steps or components by design

=item No large dependancy chains

=item No attributes (none of these: L<http://perldoc.perl.org/attributes.html>)

=item No use of END blocks

=item No use of Sub::Uplevel

=item No source filters

=back

=head1 MISSION

L<Fennec::Mission> - Why does Fennec exist?

=head1 API DOCUMENTATION

API Documentation covers object internals. See the POD within each individual
module.

=head1 FENNEC MODULE API

B<This section only covers the API for Fennec.pm. See L<Fennec::Manual> and other
documentation for other module API's.>

B<This section is not for those who simply wish to write tests, this is for
people who want to extend Fennec.>

=head2 Class methods

=over 4

=item import( %proto )

    use Fennec %proto;

Called when you use the Fennec module. %proto is key/value pairs for
configuration. Meta data keys should be placed in a hashref under the 'meta'
key.

=item my $obj = $class->new( %proto )

Create a new instance. %proto can be all the same key/value pairs as import(),
except that the meta data must be in a hashref under the 'meta' key. You must
also specify a 'caller' key with an arrayref containing a package name,
filename, and line number for the test file.

=back

=head2 Object methods

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
