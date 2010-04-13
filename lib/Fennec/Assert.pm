package Fennec::Assert;
use strict;
use warnings;

use Fennec::Util::Alias qw/
    Fennec::Runner
    Fennec::Output::Result
    Fennec::Output::Diag
/;

use Try::Tiny;
use Time::HiRes qw/time/;
use Benchmark qw/timeit :hireswallclock/;
use Carp qw/confess croak carp cluck/;
use Scalar::Util 'blessed';
use Exporter::Declare ':extend';

our @EXPORT = qw/tb_wrapper tester util result diag test_caller/;
our @CARP_NOT = qw/ Try::Tiny Benchmark /;

our $TB_RESULT;
our @TB_DIAGS;
our $TB_OK;
our %TB_OVERRIDES;
BEGIN {
    %TB_OVERRIDES = (
        _ending => sub {},
        _my_exit => sub {},
        exit => sub {},
        ok => sub {
            shift;
            my ( $ok, $name ) = @_;
            result(
                test_caller(),
                pass => $ok,
                name => $name,
            ) unless $TB_OK;
            $TB_RESULT = [ $ok, $name ];
        },
        diag => sub {
            shift;
            return if $_[0] =~ m/No tests run!/;
            diag( @_ ) unless $TB_OK;
            push @TB_DIAGS => @_;
        },
        note => sub {
            shift;
            diag( @_ ) unless $TB_OK;
            push @TB_DIAGS => @_;
        }
    );

    if ( eval { require Test::Builder; 1 }) {
        Test::Builder->new->plan('no_plan');
        for my $ref (keys %TB_OVERRIDES) {
            no warnings 'redefine';
            no strict 'refs';
            my $newref = "real_$ref";
            *{ 'Test::Builder::' . $newref } = \&$ref;
            *{ 'Test::Builder::' . $ref    } = $TB_OVERRIDES{ $ref };
        }
    }
}

sub util { goto &export }

sub tester {
    my ( $assert_class, $sub );

    $sub = pop( @_ ) if ref( $_[-1] ) && ref( $_[-1] ) eq 'CODE';
    $assert_class = shift( @_ ) if @_ > 1;
    my ( $name ) = @_;
    $assert_class = blessed( $assert_class ) || $assert_class || caller;

    croak( "You must provide a name to tester()" )
        unless $name;
    $sub ||= $assert_class->can( $name );
    croak( "No code found in '$assert_class' for exported sub '$name'" )
        unless $sub;

    my $wrapsub = sub {
        my @args = @_;
        my @outresults;
        my ( $caller, $file, $line ) = caller;
        my %caller = test_caller();
        my $return = 1;
        try {
            no warnings 'redefine';
            no strict 'refs';
            local *{ $assert_class . '::result' } = sub {
                shift( @_ ) if blessed( $_[0] );
                push @outresults => { @_ };
            };
            $sub->( @args );

            # Try to provide a minimum diag for failed tests that do not provide
            # their own.
            for my $outresult ( @outresults ) {
                if ( !$outresult->{ pass }
                && ( !$outresult->{ stderr } || !@{ $outresult->{ stderr }})) {
                    my @diag;
                    $outresult->{ stderr } = \@diag;
                    for my $i ( 0 .. (@args - 1)) {
                        my $arg = $args[$i];
                        $arg = 'undef' unless defined( $arg );
                        next if "$arg" eq $outresult->{ name } || "";
                        push @diag => "\$_[$i] = '$arg'";
                    }
                }

                $return &&= result(
                    %caller,
                    %$outresult
                ) if $outresult;
            }
        }
        catch {
            result(
                pass => 0,
                %caller,
                stderr => [ "$name died: $_" ],
            );
            $return = 0;
        };
        return $return;
    };

    my $proto = prototype( $sub );
    my $newsub = $proto ? eval "sub($proto) { \$wrapsub->( \@_ )}" || die($@)
                        : $wrapsub;

    $assert_class->export( $name, $newsub );
}

sub diag {
    shift( @_ ) if blessed( $_[0] )
                && blessed( $_[0] )->isa( __PACKAGE__ );
    Fennec::Output::Diag->new( stderr => \@_ )->write;
}

sub result {
    shift( @_ ) if blessed( $_[0] )
                && blessed( $_[0] )->isa( __PACKAGE__ );
    return unless @_;
    my %proto = @_;
    my $res = Result->new(
        @proto{qw/file line/} ? () : test_caller(),
        %proto,
    );
    $res->write;
    return $res->pass;
}

sub tb_wrapper(&) {
    shift( @_ ) if blessed( $_[0] )
                && blessed( $_[0] )->isa( __PACKAGE__ );
    my ( $orig ) = @_;
    my $proto = prototype( $orig );
    my $wrapper = sub {
        my @args = @_;
        local $TB_OK = 1;
        local ( $TB_RESULT, @TB_DIAGS );
        $orig->( @args );
        return diag( @TB_DIAGS ) unless $TB_RESULT;
        return result(
            pass      => $TB_RESULT->[0],
            name      => $TB_RESULT->[1],
            stderr    => [@TB_DIAGS],
        );
    };
    return $wrapper unless $proto;
    # Preserve the prototype
    return eval "sub($proto) { \$wrapper->(\@_) }";
}

sub test_caller {
    my $current = 1;
    my ( $caller, $file, $line );
    do {
        ( $caller, $file, $line ) = caller( $current );
        $current++;
    } while $caller && !$caller->isa( 'Fennec::TestFile' );

    return (
        file => $file || "N/A",
        line => $line || "N/A",
    );
}

1;

=head1 DESCRIPTION

Fennec::Assert - Assertions (tester functions) for Fennec.

=head1 SYNOPSYS

    package My::Assert;
    use Fennec::Assert;

    tester ok => sub($$) {
        my ( $status, $name ) = @_;
        result( pass => $status, name => $name );
    };
    util diag => sub {
        # diag() is exported by Fennec::Assert
        diag( @_ );
    };

    tester 'is';
    sub is {
        ...
    }

    1;

=head1 WRAPPING TEST::BUILDER

This is actual code from Fennec 0.11 as an example

    package Fennec::Assert::TBCore::More;
    use strict;
    use warnings;

    use Fennec::Assert;
    use Fennec::Output::Result;
    require Test::More;

    our @LIST = qw/ ok is isnt like unlike cmp_ok can_ok isa_ok new_ok pass fail
                    use_ok require_ok is_deeply /;

    for my $name ( @LIST ) {
        no strict 'refs';
        next unless Test::More->can( $name );
        tester $name => tb_wrapper \&{ 'Test::More::' . $name };
    }

    # Technically "util 'diag';" would work, but it is less clear since diag()
    # is imported.
    util diag => \&diag;

    util note => \&diag;

    1;

=head1 MAGIC

=over 4

=item Test::Builder overrides

L<Fennec::Assert> will override some subs within Test::Bulder so that it
generates L<Fennec::Output> objects instead of printing to STDIN and STDERR.

=item Subclassing

When you use L<Fennec::Assert> it will automatically make your package a
subclass of L<Fennec::Assert>.

    package My::Assert;
    use strict;
    use warnings;

    # Import functions AND add 'Fennec::Assert' to @ISA.
    use Fennec::Assert;

This is important because it gives your package an import() and some export
helper functions that allow the 'tester' and 'util' methods to define exports
that may not actually be subs in your package. This provides an export_to
method that Fennec uses to provide your assert functions to tests, it also
allows 'use My::Assert' to work as expected.

=back

=head1 EXPORTED FUNCTIONS

Note: These also work in method form, if your assert class can be instantiated
as an object you can call $instance->NAME().

=over 4

=item $newsub = tb_wrapper( sub { ... } )

=item $newsub = tb_wrapper( \&function_name )

Wrap a Test::Builder function (such as is_deeply()) with a Fennec wrapper that
provides extra information such as diagnostics, benchmarking, and scope/caller
information to generated results.

The wrapper function will be defined with the same prototype as the function
being wrapped. If the original was defined as sub($$) {...} then $newsub will
also have the ($$) prototype.

=item tester( 'name' )

=item tester( name => sub { ... })

In the first form you export a package sub as a tester by name. In the second
form you create a new export with an anonymous sub. Note: Your function will be
wrapped inside another function that provides extra information such as
diagnostics, benchmarking, and scope/caller information to generated results.

The wrapper function will be defined with the same prototype as the function
being wrapped. If the original was defined as sub($$) {...} then $newsub will
also have the ($$) prototype.

=item util( 'name' )

=item util( name => sub { ... })

In the first form you export a package sub as a util by name. In the second
form you create a new export with an anonymous sub. Note: Utility functions are
not wrapped like tester functions are, this means no free diagnostics, scope,
or caller. However unlike tester() a util can produce any number of results, or
no results at all.

=item %line_and_filename = test_caller()

Returns a hash containing the keys 'line' and 'file' which hold the filename
and line number of the most recent L<Fennec::TestFile> caller. It does not rely
on knowing how deep you are in the stack, or tracking anything, it searches the
stack from current backwords until it finds a testfile.

This is used in tester functions that have been wrapped to provide a line
number and filename to results. If you generate results in util or other
non-tester functions you can use this to add the line number and filename.

=item result( %result_proto )

Create and write a test result. %result_proto can have any keys that are valid
L<Fennec::Output::Result> construction parameters.

=item diag( @messages )

Issue a L<Fennec::Output::Diag> object with the provided messages.

=back

=head1 CLASS METHODS

All of these are inherited by any class that uses L<Fennec::Assert>

=over 4

=item my $items = $class->exports()

Retrieve a hashref containing { name => sub {} } pairs for all exports provided
by your module.

=item $class->export_to( $dest_class )

=item $class->export_to( $dest_class, $prefix )

Export all exported subs to the specified package. If a prefix is specified
then all exported subs will be exported with that prefix.

=item $class->import()

=item use Fennec::Assert

=item $class->import( $prefix )

=item use Fennec::Assert qw/prefix/

Called automatically when you use L<Fennec::Assert>. It will import all
exported subs into the calling class. If a prefix is specified then all
exported subs will be exported with that prefix. If the package being used is a
L<Fennec::Assert> itself then @ISA will be modified to subclass the calling
package. Assert subclasses do not modify the @ISA whent hey are used.

=back

=head1 EARLY VERSION WARNING

L<Fennec> is still under active development, many features are untested or even
unimplemented. Please give it a try and report any bugs or suggestions.

=head1 MANUAL

L<Fennec::Manual> - Advanced usage and extending Fennec.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
