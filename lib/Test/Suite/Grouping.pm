package Test::Suite::Grouping;
use strict;
use warnings;
use Carp;

#{{{ POD

=pod

=head1 NAME

Test::Suite::Grouping - Functions for creating/manipulating cases and sets.

=head1 DESCRIPTION

This package is repsonsible for the case/set creation functionality. You will
probably never need to use this directly.

=head1 EARLY VERSION WARNING

This is VERY early version. Test::Suite does not run yet.

Please go to L<http://github.com/exodist/Test-Suite> to see the latest and
greatest.

=head1 CLASS METHODS

=over 4

=item $class->export_to( $package )

Export all functions to the specified package.

=back

=cut

#}}}

sub export_to {
    my $class = shift;
    my ( $package ) = @_;
    return 1 unless $package;

    {
        my $us = $class . '::';
        no strict 'refs';
        my @subs = grep { defined( *{$us . $_}{CODE} )} keys %$us;
        for my $sub ( @subs ) {
            *{ $package . '::' . $sub } = \&$sub;
        }
    }
}

=head1 EXPORTABLE FUNCTIONS

=over 4

=item test_set( $name, $code )

=item test_set( $name, %proto )

Define a test set in the calling test class.

=cut

sub test_set {
    my $name = shift;
    croak( "You must provide a set name, and it must not be a reference" )
        if !$name || ref $name;

    my $code = shift if @_ == 1;
    my %proto = ( method => $code, @_ );
    my ( $package ) = caller;

    $package->add_set( $name, %proto );
}

=item test_case( $name, $code )

=item test_case( $name, %proto )

Define a test case in the calling test class.

=cut

sub test_case {
    my $name = shift;
    croak( "You must provide a case name, and it must not be a reference" )
        if !$name || ref $name;

    my $code = shift if @_ == 1;
    my %proto = ( method => $code, @_ );
    my ( $package ) = caller;

    $package->add_case( $name, %proto );
}

1;

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
