package Fennec::Group;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Runner;
use Fennec::Util::Accessors;
use Fennec::Test;
use Carp;

Accessors qw/ parent children name method file line /;

sub function    {}
sub depends     {[]}
sub alias       { shift->current }
sub current     { confess "No current group" }
sub depth       { 0 }

sub new {
    my $class = shift;
    my $name = shift;
    my ( $method, %proto ) = $class->_method_proto( @_ );
    confess( "$class must be created with a method " )
        unless $method;

    my $self = bless({ %proto, method => $method, children => [] }, $class );
    my $init = $self->can( 'init' ) || $self->can( 'initialize' );
    $self->$init( $name, @_ ) if $init;
    return $self;
}

sub _method_proto {
    my $class = shift;
    return ( $_[0] ) if @_ == 1;
    my %proto = @_;
    return ( $proto{ method }, %proto );
}

sub tests {
    my $self = shift;
    return grep { $_->isa('Fennec::Group::Tests') } @{ $self->children };
}

sub groups {
    my $self = shift;
    return grep { !$_->isa('Fennec::Group::Tests') } @{ $self->children };
}

sub add_item {
    my $self = shift;
    my ( $item ) = @_;
    push @{ $self->children } => $item;
    $item->parent( $self );
    return $self;
}

sub run_method_as_current {
    my $self = shift;
    my ( $method, @args ) = @_;
    return $self->run_method_as_current_on( $method, $self, @args );
}

sub run_method_as_current_on {
    my $self = shift;
    my ( $method, $obj, @args ) = @_;
    my $depth = $self->depth + 1;

    no warnings 'redefine';
    local *current = sub { $self };
    local *depth = sub { $depth };
    return $obj->$method( @args );
}

sub run_sub_as_current {
    my $self = shift;
    my ( $sub, @args ) = @_;
    my $depth = $self->depth + 1;

    no warnings 'redefine';
    local *current = sub { $self };
    local *depth = sub { $depth };
    return $sub->( @args );
}

sub build {
    my $self = shift;
    $self->run_method_as_current_on( $self->method, $self->test );
    $self->build_children;
    return $self;
}

sub build_children {
    my $self = shift;
    $_->build for @{ $self->children };
    return $self;
}

sub current_add_item {
    shift->current->add_item( @_ );
}

sub add_items {
    my $class_or_self = shift;
    $class_or_self->add_item( $_ ) for @_;
}

sub _tests {
    my $self = shift;
    my @tests = $self->tests;
    push @tests => $_->_tests for @{ $self->children };
    return @tests;
}

sub run_on {
    my $self = shift;
    my ( $on, @args ) = @_;
    my $code = $self->method;
    $on->$code( @args );
}

sub test {
    my $self = shift;

    unless ( $self->{ test }) {
        my $parent = $self->parent;
        $self->{ test } = $parent->isa( Test )
            ? $parent
            : $parent->test;
    }

    return $self->{ test };
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
