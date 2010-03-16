package Fennec::Group;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Runner;
use Fennec::Util::Accessors;
use Fennec::Util::Abstract;
use Carp;

Accessors qw/ parent children name method file line /;
Abstract  qw/ tests add_item /;

sub function    {}
sub depends     {[]}
sub alias       { shift->current }
sub current     { confess "No current group" }
sub depth       { 0 }

sub new {
    my $class = shift;
    my $name = shift;
    my ( $method, %proto ) = $class->_method_proto( @_ );
    confess( "$class must be created with a method" )
        unless $method;

    my $self = bless({ %proto, method => $method }, $class );
    my $init = $self->can( 'init' ) || $self->can( 'initialize' );
    $self->$init( $name, @_ ) if $init;
    return $self;
}

sub _method_proto {
    my $class = shift;
    return ( $_[0] ) if @_ == 1;
    %proto = @_;
    return ( $proto{ method }, %proto );
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

    local *current = sub { $self };
    local *depth = sub { $depth };
    return $obj->$method( @args );
}

sub run_sub_as_current {
    my $self = shift;
    my ( $sub, @args ) = @_;
    my $depth = $self->depth + 1;

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
    $_->build for @{ $self->children }
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
