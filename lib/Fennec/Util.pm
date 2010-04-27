package Fennec::Util;
use strict;
use warnings;

use Carp qw/carp confess croak cluck/;

sub workflow_stack {
    my $class = shift;
    my ( $workflow ) = @_;
    return wantarray ? () : 'No Workflow' unless $workflow;

    my @list;
    my $current = $workflow;

    do {
        push @list => $current;
    } while (( $current = $current->parent ) && $current->isa( 'Fennec::Workflow' ));
    return reverse map { $_->name } @list if wantarray;

    my @lines = map {
        join( ' ', $_->name || "UNNAMED", '-', $_->file || "UNKNOWN FILE", 'at', $_->line || "UNKNOWN LINE" )
    } @list;
    return join( "\n", @lines );
}

sub package_subs {
    my $class = shift;
    my ( $package, $match ) = @_;
    $package = $package . '::';
    no strict 'refs';
    my @list = grep { defined( *{$package . $_}{CODE} )} keys %$package;
    return @list unless $match;
    return grep { $_ =~ $match } @list;
}

sub package_sub_map {
    my $class = shift;
    my ( $package, $match ) = @_;
    croak( "Must specify a package" ) unless $package;
    my @list = $class->package_subs( @_ );
    return map {[ $_, $package->can( $_ )]} @list;
}

1;

=head1 NAME

Fennec::Util - Misc utilities

=head1 CLASS METHODS

=over 4

=item @names = workflow_stack( $workflow )

=item $stack = workflow_stack( $workflow )

Like a stacktrace, except it returns the workflow and its parents up to the
root including filename and line number on which they were defined. In array
context it simply returns the list of workflow names up to the parent.

=item @sub_names = $class->package_subs( $package )

=item @sub_names = $class->package_subs( $package, $regex )

Get the list of all subs in a package, if a regex is provided it will be used
to filter the list.

=item %map = $class->package_sub_map( $package )

=item %map = $class->package_sub_map( $package, $regex )

Get a map of (sub_name => $coderef) for all subs in a package. If a regex is
provided use it to filter the list of subs.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
