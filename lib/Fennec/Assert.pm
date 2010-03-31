package Fennec::Assert;
use strict;
use warnings;

use Fennec::Runner;
use Fennec::Output::Result;
use Fennec::Output::Diag;

use Time::HiRes qw/time/;
use Benchmark qw/timeit :hireswallclock/;
use Carp qw/confess croak carp cluck/;
use Scalar::Util 'blessed';
use Try::Tiny;

our @EXPORT = qw/tb_wrapper tester util result diag/;
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
                _first_test_caller_details(),
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

sub exports {
    my $class = shift;
    no strict 'refs';
    return {
        ( map { $_ => $_ } @{ $class . '::EXPORT' }),
        %{ $class . '::EXPORT' },
    };
}

sub export_to {
    my $class = shift;
    my ( $dest, $prefix ) = @_;
    my $exports = $class->exports;
    for my $name ( keys %$exports ) {
        my $sub = $exports->{ $name };
        $sub = $class->can( $sub ) unless ref $sub eq 'CODE';

        croak( "Could not find sub $name in $class for export" )
            unless ref($sub) eq 'CODE';

        $name = $prefix . $name if $prefix;
        no strict 'refs';
        *{ $dest . '::' . $name } = $sub;
    }
}

sub import {
    my $class = shift;
    my ( $prefix ) = @_;
    my $caller = caller;
    $class->export_to( $caller, $prefix );

    # Assert subclasses should not modify @ISA
    return if $class ne __PACKAGE__;

    no strict 'refs';
    push @{ $caller . '::ISA' } => __PACKAGE__
        unless grep { $_ eq __PACKAGE__ } @{ $caller . '::ISA' };
}

sub util {
    my $caller;
    $caller = shift( @_ ) if blessed( $_[0] )
                          && blessed( $_[0] )->isa( __PACKAGE__ );
    $caller = blessed( $caller ) || $caller || caller;
    my ( $name, $sub ) = @_;
    croak( "You must provide a name to util()" )
        unless $name;
    $sub ||= $caller->can( $name );
    croak( "No sub found for function $name" )
        unless $sub;

    no strict 'refs';
    my $export = \%{ $caller . '::EXPORT' };
    $export->{ $name } = $sub;
}

sub tester {
    my $assert_class;
    $assert_class = shift( @_ ) if blessed( $_[0] )
                                && blessed( $_[0] )->isa( __PACKAGE__ );
    $assert_class = blessed( $assert_class ) || $assert_class || caller;
    my ( $name, $sub ) = @_;
    croak( "You must provide a name to tester()" )
        unless $name;
    $sub ||= $assert_class->can( $name );
    croak( "No sub found for function $name" )
        unless $sub;

    my $wrapsub = sub {
        my @args = @_;
        my $outresult;
        my $benchmark;
        my ( $caller, $file, $line ) = caller;
        my %caller = _first_test_caller_details();
        try {
            no warnings 'redefine';
            no strict 'refs';
            local *{ $assert_class . '::result' } = sub {
                shift( @_ ) if blessed( $_[0] )
                            && blessed( $_[0] )->isa( __PACKAGE__ );
                croak( "tester functions can only generate a single result." )
                    if $outresult;
                $outresult = { @_ }
            };
            $benchmark = timeit( 1, sub { $sub->( @args )});

            # Try to provide a minimum diag for failed tests that do not provide
            # their own.
            if ( !$outresult->{ pass }
            && ( !$outresult->{ stdout } || !@{ $outresult->{ stdout }})) {
                my @diag;
                $outresult->{ stdout } = \@diag;
                for my $i ( 0 .. (@args - 1)) {
                    my $arg = $args[$i];
                    $arg = 'undef' unless defined( $arg );
                    next if "$arg" eq $outresult->{ name } || "";
                    push @diag => "\$_[$i] = '$arg'";
                }
            }

            result(
                %caller,
                benchmark => $benchmark || undef,
                %$outresult
            ) if $outresult;
        }
        catch {
            result(
                pass => 0,
                %caller,
                stdout => [ "$name died: $_" ],
            );
        };
    };

    my $proto = prototype( $sub );
    my $newsub = $proto ? eval "sub($proto) { \$wrapsub->( \@_ )}" || die($@)
                        : $wrapsub;

    no strict 'refs';
    my $export = \%{ $assert_class . '::EXPORT' };
    $export->{ $name } = $newsub;
}

sub diag {
    shift( @_ ) if blessed( $_[0] )
                && blessed( $_[0] )->isa( __PACKAGE__ );
    Fennec::Output::Diag->new( stdout => \@_ )->write;
}

sub result {
    shift( @_ ) if blessed( $_[0] )
                && blessed( $_[0] )->isa( __PACKAGE__ );
    return unless @_;
    my %proto = @_;
    Result->new(
        @proto{qw/file line/} ? () : _first_test_caller_details(),
        %proto,
    )->write;
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
        my $benchmark = timeit( 1, sub { $orig->( @args )});
        return diag( @TB_DIAGS ) unless $TB_RESULT;
        return result(
            pass      => $TB_RESULT->[0],
            name      => $TB_RESULT->[1],
            benchmark => $benchmark,
            stdout    => [@TB_DIAGS],
        );
    };
    return $wrapper unless $proto;
    # Preserve the prototype
    return eval "sub($proto) { \$wrapper->(\@_) }";
}

sub _first_test_caller_details {
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

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
