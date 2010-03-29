package Fennec;
use strict;
use warnings;

use Carp;
use Fennec::Runner;
use Fennec::TestFile;
use Fennec::TestFile::Functions;

our $VERSION = "0.010";
our $TEST_CLASS;

sub clear_test_class { $TEST_CLASS = undef }
sub test_class { $TEST_CLASS }

sub import {
    my $class = shift;
    my %proto = @_;
    my ( $caller, $file, $line ) = caller;
    my ( $workflows, $asserts ) = @proto{qw/ workflows asserts /};
    my $standalone = delete $proto{ standalone };

    if ( $standalone ) {
        'Fennec::Runner'->init(
            %$standalone,
            files => [ [ $caller, $file, $line ] ],
            filetypes => [ 'Standalone' ]
        );
        no strict 'refs';
        *{ $caller . '::start' } = sub { Runner->start };
    }

    croak "Test runner not found"
        unless Runner;
    croak( "You must put your tests into a package, not main" )
        if $caller eq 'main';

    $TEST_CLASS = $caller;

    {
        no strict 'refs';
        push @{ $caller . '::ISA' } => TestFile;
    }

    my $functions = Functions->new( $workflows );
    $functions->export_to( $caller );

    $asserts ||= Runner->default_asserts || [ qw/ Core / ];
    export_package_to( 'Fennec::Assert::' . $_, $caller )
        for @$asserts;

    1;
}

sub export_package_to {
    my ( $from, $to ) = @_;
    eval "require $from; 1" || die( $@ );
    $from->export_to( $to );
}

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
