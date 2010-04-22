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
    return reverse @list if wantarray;

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

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
