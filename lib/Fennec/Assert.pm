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

our $TB_RESULT;
our @TB_DIAGS;
our $TB_OK;
our %TB_OVERRIDES = (
    ok => sub {
        carp( 'Test::Builder result intercepted but ignored.' )
            unless $TB_OK;
        shift;
        my ( $ok, $name ) = @_;
        $TB_RESULT = [ $ok, $name ];
    },
    diag => sub {
        carp( 'Test::Builder diag intercepted but ignored.' )
            unless $TB_OK;
        shift;
        push @TB_DIAGS => @_;
    },
);

if ( eval { require Test::Builder; 1 }) {
    for my $ref (keys %TB_OVERRIDES) {
        no warnings 'redefine';
        no strict 'refs';
        my $newref = "real_$ref";
        *{ 'Test::Builder::' . $newref } = \&$ref;
        *{ 'Test::Builder::' . $ref    } = $TB_OVERRIDES{ $ref };
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
    no strict 'refs';
    push @{ $caller . '::ISA' } => __PACKAGE__
        unless grep { $_ eq __PACKAGE__ } @{ $caller . '::ISA' };
}

sub util {
    my $caller = caller;
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
    my $assert_class = caller;
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
        try {
            no warnings 'redefine';
            no strict 'refs';
            local *{ $assert_class . '::result' } = sub { $outresult = { @_ }};
            $benchmark = timeit( 1, sub { $sub->( @args )});
        }
        catch {
            result(
                pass => 0,
                file => $file || "N/A",
                line => $line || "N/A",
                diag => [ "$name died: $_" ],
            );
        };
        result(
            file => $file || "N/A",
            line => $line || "N/A",
            benchmark => $benchmark || undef,
            %$outresult
        ) if $outresult;
    };

    my $proto = prototype( $sub );
    my $newsub = $proto ? eval "sub($proto) { \$wrapsub->( \@_ )}" || die($@)
                        : $wrapsub;

    no strict 'refs';
    my $export = \%{ $assert_class . '::EXPORT' };
    $export->{ $name } = $newsub;
}

sub diag {
    Fennec::Output::Diag->new( stdout => \@_ )->write;
}

sub result {
    return unless @_;
    my %proto = @_;
    use Data::Dumper;
    Result->new(
        @proto{qw/file line/} ? _first_test_caller_details() : (),
        %proto,
    )->write;
}

sub tb_wrapper(&) {
    my ( $orig ) = @_;
    my $proto = prototype( $orig );
    my $wrapper = sub {
        local $TB_OK = 1;
        local ( $TB_RESULT, @TB_DIAGS );
        $orig->( @_ );
        return diag( @TB_DIAGS ) unless $TB_RESULT;
        return result(
            pass => $TB_RESULT,
            diag => [@TB_DIAGS],
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
    } while $caller && !$caller->isa( 'Fennec::Test' );

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
