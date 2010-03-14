package Fennec::Runner::Stack;
use strict;
use warnings;

use Fennec::Runner::Stack::Node;
use Fennec::Util qw/add_accessors/;
use List::Util   qw/shuffle/;
use Carp;

add_accessors qw/stack random/;

sub new {
    my $class = shift;
    my $self = bless({ ran => 0, random => 1, @_ }, $class );
    $self->stack([ Fennec::Runner::Stack::Node->new( $self )]);
    return $self;
}

sub run {
    my $self = shift;
    return if $self->{ run }++;
    my $list = $self->traverse;
    for my $set ( $self->random ? shuffle @$list : @$list }) {
        $self->run_set( $set );
    }
}

sub run_set {
    my $self = shift;
    my ( $set ) = @_;

    return $self->run_node_set( @$set )
        if $set->[0]->isa( 'Fennec::Runner::Stack::Node' );

    return $self->run_case_set( @$set )
        if $set->[0]->isa( 'Fennec::Group::Case' );

    confess ( "Malformed test set" );
}

sub run_node_set {
    my $self = shift;
    my ( $node, @$tests ) = @$set;

    $node->run_before_all;
    for my $item ( $self->random ? shuffle @$tests : @$tests ) {
        if ( ref( $item ) eq 'ARRAY' ) {
            $self->run_set( $item );
        }
        else {
            $node->run_before_each;
            $item->run;
            $node->run_after_each;
        }
    }
    $node->run_after_all;
}

sub run_case_set {
    my $self = shift;
    my ( $case, @$tests ) = @$set;

    $case->run;
    for my $item ( $self->random ? shuffle @$tests : @$tests ) {
        $self->run_set( $item );
    }
}

sub travserse {
    my $self = shift;
    $self->{ all } ||= [ $self->stack->[0]->traverse ];
    return $self->{ all };
}

sub push {
    my $self = shift;
    my ( $item ) = @_;
    push @{ $self->stack } => $item;
}

sub pop {
    my $self = shift;
    pop @{ $self->stack };
}

sub peek {
    my $self = shift;
    return $self->stack->[-1];
}

sub sanity {
    my $self = shift;
    croak( "Cannot add test items after testing has started" )
        if $self->{ run };
    1;
}

sub add_group {
    my $self = shift;
    my ( $group ) = @_;
    $self->sanity;
    $self->peek->add_group( $group );
}

sub add_setup {
    my $self = shift;
    my ( $setup ) = @_;
    $self->sanity;
    $self->peek->add_setup( $setup );
}

sub add_tests {
    my $self = shift;
    my ( $tests ) = @_;
    $self->sanity;
    $self->peek->add_tests( $tests );
}

sub demolish {
    my $self = shift;
    $self->stack->[0]->demolish;
}

sub DESTROY {
    my $self = shift;
    $self->demolish;
}

1;
