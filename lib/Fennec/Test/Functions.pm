package Fennec::Test::Functions;
use strict;
use warnings;
use Carp;
use Fennec::Util qw/get_all_subs/;

sub export_to {
    my $class = shift;
    my ( $package ) = @_;
    return 1 unless $package;

    my @subs = grep { $_ ne 'export_to' && $_ !~ m/^_/ } get_all_subs($class);
    for my $sub ( @subs ) {
        no strict 'refs';
        *{ $package . '::' . $sub } = \&$sub;
    }
}

sub _add_group {
    my ( $type, $name, @remain ) = @_;

    croak( "You must provide a $type name, and it must not be a reference" )
        if !$name || ref $name;

    my $code = shift if @remain == 1;
    my ( $package, $filename, $line ) = caller;
    my %proto = (
        method => $code,
        @remain,
        test => $package,
        filename => $filename,
        line => $line
    );

    $type = 'Fennec::Group::' . $type;
    my $group = $type->new( $name, %proto );
    Fennec::Runner->get->stack->add_group( $group );
}

sub _add_prepare {
    my ( $type, $code ) = @_;

    my ( $package, $filename, $line ) = caller;
    my %proto = (
        method => $code,
        test => $package,
        filename => $filename,
        line => $line
    );

    $type = 'Fennec::Prepare::' . $type;
    my $prepare = $type->new( $name, %proto );
    Fennec::Runner->get->stack->add_prepare( $prepare );
}

sub _add_tests {
    my ( $type, $name, @remain ) = @_;

    croak( "You must provide a $type name, and it must not be a reference" )
        if !$name || ref $name;

    my $code = shift if @remain == 1;
    my ( $package, $filename, $line ) = caller;
    my %proto = (
        method => $code,
        @remain,
        test => $package,
        filename => $filename,
        line => $line
    );

    $type = 'Fennec::Test::' . $type;
    my $group = $type->new( $name, %proto );
    Fennec::Runner->get->stack->add_tests( $group );
}

sub test_set {
    unshift @_ => 'Set';
    goto &_add_group;
}

sub test_case {
    unshift @_ =>  'Case';
    goto &_add_group;
}
sub describe {
    unshift @_ => 'Describe';
    goto &_add_group;
}

sub tests { goto &it_once }
sub it { goto &it_once }

sub it_once {
    unshift @_ => 'Once';
    goto &_add_tests;
}

sub it_each {
    unshift @_ => 'Each';
    goto &_add_tests;
}

sub before_each(&) {
    unshift @_ => 'BeforeEach';
    goto &_add_prepare;
}

sub after_each(&) {
    unshift @_ => 'AfterEach';
    goto &_add_prepare;
}

sub before_all(&) {
    unshift @_ => 'BeforeAll';
    goto &_add_prepare;
}

sub after_all(&) {
    unshift @_ => 'AfterAll';
    goto &_add_prepare;
}

sub bail_out {
    my ( $reason ) = @_;
    Fennec::Runner->get->bail_out( $reason );
}

1;

=pod

=head1 NAME

Fennec::Test::Functions - Functions for creating/manipulating cases and sets.

=head1 DESCRIPTION

This package is repsonsible for the case/set creation functionality. You will
probably never need to use this directly.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 CLASS METHODS

=over 4

=item $class->export_to( $package )

Export all functions to the specified package.

=back

=head1 EXPORTABLE FUNCTIONS

=over 4

=item test_set( $name, $code )

=item test_set( $name, %proto )

Define a test set in the calling test class.

=item test_case( $name, $code )

=item test_case( $name, %proto )

Define a test case in the calling test class.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
