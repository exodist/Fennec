package Fennec::Test::Stack;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Test::Stack::Node;
use Fennec::Test::Function;
use Fennec::Util::Accessors;
use Fennec::Runner;
use Carp;

use List::Util qw/shuffle/;

Accessors qw/root _nodes/;

sub random { Runner->current->random }

sub new {
    my $class = shift;
    my $self = bless({ ran => 0, _nodes => [], @_ }, $class );
    $self->start_node([ Node->new ]);
    return $self;
}

sub traverse {
    my $self = shift;
    $self->{ traverse } ||= [ $self->root->traverse ];
    return $self->{ traverse };
}

sub push {
    my $self = shift;
    my ( $item ) = @_;
    push @{ $self->_nodes } => $item;
}

sub pop {
    my $self = shift;
    pop @{ $self->_nodes };
}

sub peek {
    my $self = shift;
    return $self->_nodes->[-1];
}

sub run {
    my $self = shift;
    croak( "Stack already running" )
        if $self->{ run }++;

    $self->run_set( $self->traverse );
}

sub run_set {
    my $self = shift;
    my @set = @{$_[0]};
    @set = shuffle @set if $self->random;
    for my $item ( @set ) {
        my $ref = ref $item;
        if ( $ref eq 'HASH' ) {
            $self->run_subset( $item );
        }
        else {
            $item->run;
        }
    }
}

sub run_subset {
    my $self = shift;
    $_->run for @{ $item->{ setup }};
    $self->run_set( $item->{ tests } );
    $_->run for @{ $item->{ teardown }};
}

__END__

sub run_set {
    my $self = shift;
    my ( $set ) = @_;

    return $self->run_node_set( @$set )
        if $set->[0]->isa( Node );

    return $self->run_function_set( @$set )
        if $set->[0]->isa( Function );

    confess ( "Malformed test set" );
}

sub run_node_set {
    my $self = shift;
    my ( $node, @$tests ) = @$set;

    try {
        $node->run_before_all;
        for my $item ( $self->random ? shuffle @$tests : @$tests ) {
            if ( ref( $item ) eq 'ARRAY' ) {
                $self->run_set( $item );
            }
            else {
                $node->run_before_each;
                try {
                    $item->run;
                }
                catch {
                    $Fennec::Result->fail_item( $item, $node, $_ )
                }
                $node->run_after_each;
            }
        }
        $node->run_after_all;
    };
}

sub run_case_set {
    my $self = shift;
    my ( $case, $node, @$tests ) = @$set;

    try {
        $case->run;
        for my $item ( $self->random ? shuffle @$tests : @$tests ) {
            $self->run_set( $item );
        }
    }
    catch {
        $Fennec::Result->fail_item( $case, $node, $_ );
    }
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
