package Fennec::Runner::Stack::Node;
use strict;
use warnings;

use Fennec::Util qw/add_accessors/;
use Scalar::Util qw/blessed/;

add_accessors qw/_groups _tests _setups parent children stack group group_child_cache/;

sub cases     { @{ $_[0]->_groups->{ Case     }}}
sub sets      { @{ $_[0]->_groups->{ Set      }}}
sub describes { @{ $_[0]->_groups->{ Describe }}}

sub before_all  { @{ $_[0]->_setups->{ BeforeAll  }}}
sub before_each { @{ $_[0]->_setups->{ BeforeEach }}}
sub after_all   { @{ $_[0]->_setups->{ AfterAll   }}}
sub after_each  { @{ $_[0]->_setups->{ AfterEach  }}}

sub test_once   { @{ $_[0]->_tests->{ Once }}}
sub test_each   { @{ $_[0]->_tests->{ Each }}}

sub deep_before_each { $_[0]->deep( 'before_each'   )}
sub deep_after_each  { $_[0]->deep( 'after_each', 1 )}
sub deep_test_each   { $_[0]->deep( 'test_each'     )}

sub new {
    my $class = shift;
    my ( $stack, $parent, $group ) = @_;
    my $self = bless(
        {
            _groups  => {},
            _tests   => {},
            _setups  => {},
            children => [],
            parent   => $parent || undef,
            group    => $group || $parent ? undef : croak( "Child nodes require a group" ),
            stack    => $stack || croak( "You must provide a stack" ),
            group_child_cache => {},
        },
        $class
    );

    return $self;
}

sub traverse {
    my $self = shift;
    my $class = blessed( $self );
    my @tests = $self->test_sets;

    for my $describe ( $self->describes ) {
        push @tests => $self->_traverse_child_for_group( $describe );
    }

    for my $case ( $self->cases ) {
        my @case_tests;
        for my $set ( $self->sets ) {
            my $cp = $case->partition || "";
            my $sp = $set->partition || "";
            next if $cp ne $sp;
            push @case_tests => $self->_traverse_child_for_group( $set );
        }
        push @tests => [ $case, \@case_tests ];
    }

    return [ $self, @tests ];
        if ( $self->before_all || $self->after_all );

    return @tests;
}

sub _traverse_child_for_group {
    my $self = shift;
    my ( $group ) = @_;

    unless ( $self->group_child_cache->{ $group }) {
        my $child = $class->new( $self->stack, $self, $group );
        push @{ $self->children } => $child;

        $self->stack->push( $child );
        $group->run;
        my @tests = $child->travserse;
        $self->stack->pop;

        $self->group_child_cache->{ $group } = \@tests;
    }

    return @{ $self->group_child_cache->{ $group }};
}

sub test_sets {
    my $self = shift;
    my @out;

    for my $test ( $self->test_once, $self->deep_test_each ) {
        push @out => [ $self, $test ];
    }

    return @out;
}

sub add_group {
    my $self = shift;
    my ( $group ) = @_;
    my $type = $group->type;
    push @{ $self->_groups->{ $type }} => $group;
}

sub add_setup {
    my $self = shift;
    my ( $setup ) = @_;
    my $type = $setup->type;
    push @{ $self->_setups->{ $type }} => $setup;
}

sub add_tests {
    my $self = shift;
    my ( $tests ) = @_;
    my $type = $tests->type;
    push @{ $self->_tests->{ $type }} => $tests;
}

sub run_before_each {
    my $self = shift;
    $_->run for $self->deep_before_each;
}

sub run_before_all {
    my $self = shift;
    $_->run for $self->before_all;
}

sub run_after_each {
    my $self = shift;
    $_->run for $self->deep_after_each;
}

sub run_after_all {
    my $self = shift;
    $_->run for $self->after_all;
}

sub deep {
    my $self = shift;
    my ( $sub, $reverse ) = @_;

    my @plist $self->parent->deep( $sub )
        if $self->parent;

    my @list =>$self->$sub;

    return $reverse ? ( @list, @plist ) : ( @plist, @list );
}

1;
