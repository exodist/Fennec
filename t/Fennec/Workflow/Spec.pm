package TEST::Fennec::Workflow::Spec;
use strict;
use warnings;

use Fennec workflows => [ 'Spec' ],
           sort => 1,
           no_fork => 1;

use Fennec::Util::Accessors;

Accessors qw/ state /;

sub init {
    my $self = shift;
    $self->state({});
}

describe '0 - First' => sub {
    my $self = shift;

    before_all { $self->state->{ top_before_all }++ };
    after_all { $self->state->{ top_after_all }++ };

    before_each { $self->state->{ top_before_each }++ };
    after_each { $self->state->{ top_after_each }++ };

    it one => sub {
        my $self = shift;
        is( $self->state->{ top_before_all }, 1, "top_before_all" );
        is( $self->state->{ top_after_all }, undef, "top_after_all" );
        is( $self->state->{ top_before_each }, 1, "top_before_each" );
        is( $self->state->{ top_after_each }, undef, "top_after_each" );
    };
    it two => sub {
        my $self = shift;
        is( $self->state->{ top_before_all }, 1, "top_before_all" );
        is( $self->state->{ top_after_all }, undef, "top_after_all" );
        is( $self->state->{ top_before_each }, 2, "top_before_each" );
        is( $self->state->{ top_after_each }, 1, "top_after_each" );
    };
    it three => sub {
        my $self = shift;
        is( $self->state->{ top_before_all }, 1, "top_before_all" );
        is( $self->state->{ top_after_all }, undef, "top_after_all" );
        is( $self->state->{ top_before_each }, 3, "top_before_each" );
        is( $self->state->{ top_after_each }, 2, "top_after_each" );
    };

    describe '0 - First - Child' => sub {
        before_all { $self->state->{ child_before_all }++ };
        after_all { $self->state->{ child_after_all }++ };

        before_each { $self->state->{ child_before_each }++ };
        after_each { $self->state->{ child_after_each }++ };

        it one => sub {
            my $self = shift;
            is( $self->state->{ top_before_all }, 1, "top_before_all" );
            is( $self->state->{ top_after_all }, undef, "top_after_all" );
            is( $self->state->{ top_before_each }, 4, "top_before_each" );
            is( $self->state->{ top_after_each }, 3, "top_after_each" );
            is( $self->state->{ child_before_all }, 1, "child_before_all" );
            is( $self->state->{ child_after_all }, undef, "child_after_all" );
            is( $self->state->{ child_before_each }, 1, "child_before_each" );
            is( $self->state->{ child_after_each }, undef, "child_after_each" );
        };
        it two => sub {
            my $self = shift;
            is( $self->state->{ top_before_all }, 1, "top_before_all" );
            is( $self->state->{ top_after_all }, undef, "top_after_all" );
            is( $self->state->{ top_before_each }, 4, "top_before_each" );
            is( $self->state->{ top_after_each }, 3, "top_after_each" );
            is( $self->state->{ child_before_all }, 1, "child_before_all" );
            is( $self->state->{ child_after_all }, undef, "child_after_all" );
            is( $self->state->{ child_before_each }, 2, "child_before_each" );
            is( $self->state->{ child_after_each }, 1, "child_after_each" );
        };
        it three => sub {
            my $self = shift;
            is( $self->state->{ top_before_all }, 1, "top_before_all" );
            is( $self->state->{ top_after_all }, undef, "top_after_all" );
            is( $self->state->{ top_before_each }, 4, "top_before_each" );
            is( $self->state->{ top_after_each }, 3, "top_after_each" );
            is( $self->state->{ child_before_all }, 1, "child_before_all" );
            is( $self->state->{ child_after_all }, undef, "child_after_all" );
            is( $self->state->{ child_before_each }, 3, "child_before_each" );
            is( $self->state->{ child_after_each }, 2, "child_after_each" );
        };
    };

    describe '0 - First - Child2' => sub {
        before_each { $self->state->{ child2_before_each }++ };
        after_each { $self->state->{ child2_after_each }++ };

        it one => sub {
            my $self = shift;
            is( $self->state->{ top_before_all }, 1, "top_before_all" );
            is( $self->state->{ top_after_all }, undef, "top_after_all" );
            is( $self->state->{ top_before_each }, 5, "top_before_each" );
            is( $self->state->{ top_after_each }, 4, "top_after_each" );
            is( $self->state->{ child2_before_each }, 1, "child_before_each" );
            is( $self->state->{ child2_after_each }, undef, "child_after_each" );
        };
        it two => sub {
            my $self = shift;
            is( $self->state->{ top_before_all }, 1, "top_before_all" );
            is( $self->state->{ top_after_all }, undef, "top_after_all" );
            is( $self->state->{ top_before_each }, 6, "top_before_each" );
            is( $self->state->{ top_after_each }, 5, "top_after_each" );
            is( $self->state->{ child2_before_each }, 2, "child_before_each" );
            is( $self->state->{ child2_after_each }, 1, "child_after_each" );
        };
        it three => sub {
            my $self = shift;
            is( $self->state->{ top_before_all }, 1, "top_before_all" );
            is( $self->state->{ top_after_all }, undef, "top_after_all" );
            is( $self->state->{ top_before_each }, 7, "top_before_each" );
            is( $self->state->{ top_after_each }, 6, "top_after_each" );
            is( $self->state->{ child2_before_each }, 3, "child_before_each" );
            is( $self->state->{ child2_after_each }, 2, "child_after_each" );
        };
    };
};

tests 'Z - Run this last' => sub {
    my $self = shift;
    is( $self->state->{ top_before_all }, 1, "top_before_all" );
    is( $self->state->{ top_after_all }, 1, "top_after_all" );
    is( $self->state->{ top_before_each }, 7, "top_before_each" );
    is( $self->state->{ top_after_each }, 7, "top_after_each" );
    is( $self->state->{ child_before_all }, 1, "child_before_all" );
    is( $self->state->{ child_after_all }, 1, "child_after_all" );
    is( $self->state->{ child_before_each }, 3, "child_before_each" );
    is( $self->state->{ child_after_each }, 3, "child_after_each" );
    is( $self->state->{ child2_before_each }, 3, "child_before_each" );
    is( $self->state->{ child2_after_each }, 3, "child_after_each" );
};

1;
