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
        before_all { $self->state->{ child_before_all2 }++ };
        after_all { $self->state->{ child_after_all2 }++ };

        before_each { $self->state->{ child_before_each }++ };
        after_each { $self->state->{ child_after_each }++ };
        before_each { $self->state->{ child_before_each2 }++ };
        after_each { $self->state->{ child_after_each2 }++ };

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
            is( $self->state->{ child_before_all2 }, 1, "child_before_all" );
            is( $self->state->{ child_after_all2 }, undef, "child_after_all" );
            is( $self->state->{ child_before_each2 }, 1, "child_before_each" );
            is( $self->state->{ child_after_each2 }, undef, "child_after_each" );
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
            is( $self->state->{ child_before_all2 }, 1, "child_before_all" );
            is( $self->state->{ child_after_all2 }, undef, "child_after_all" );
            is( $self->state->{ child_before_each2 }, 2, "child_before_each" );
            is( $self->state->{ child_after_each2 }, 1, "child_after_each" );

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
            is( $self->state->{ child_before_all2 }, 1, "child_before_all" );
            is( $self->state->{ child_after_all2 }, undef, "child_after_all" );
            is( $self->state->{ child_before_each2 }, 3, "child_before_each" );
            is( $self->state->{ child_after_each2 }, 2, "child_after_each" );
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

describe '1 - second - ordering' => sub {
    my $self = shift;
    before_all { push @{ $self->{ order_before_all }} => 1 };
    before_all { push @{ $self->{ order_before_all }} => 2 };
    before_all { push @{ $self->{ order_before_all }} => 3 };
    after_all { push @{ $self->{ order_after_all }} => 1 };
    after_all { push @{ $self->{ order_after_all }} => 2 };
    after_all { push @{ $self->{ order_after_all }} => 3 };

    before_each { push @{ $self->{ order_before_each }} => 1 };
    before_each { push @{ $self->{ order_before_each }} => 2 };
    before_each { push @{ $self->{ order_before_each }} => 3 };
    after_each { push @{ $self->{ order_after_each }} => 1 };
    after_each { push @{ $self->{ order_after_each }} => 2 };
    after_each { push @{ $self->{ order_after_each }} => 3 };

    it 'trigger' => sub {
        ok( 1, "Test to trigger before/after" );
    };
};

describe '2 - third - no before/after' => sub {
    my $self = shift;
    it '2 - trigger' => sub {
        my $self = shift;
        ok( 1, "Test to trigger non before/after" );
        $self->{ no_ba }++;
    }
};

describe '3 - fourth - empty' => sub {
    my $self = shift;
    $self->{ empty }++;
};

describe '4 - fifth - only afters' => sub {
    my $self = shift;
    after_all { $self->{ only_after_all }++ };
    after_each { $self->{ only_after_each }++ };
    it 'trigger' => sub {
        ok( 1, "Test to trigger only after" );
    }
};

tests '9 - Run this last' => sub {
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
    is( $self->state->{ child_before_all2 }, 1, "child_before_all" );
    is( $self->state->{ child_after_all2 }, 1, "child_after_all" );
    is( $self->state->{ child_before_each2 }, 3, "child_before_each" );
    is( $self->state->{ child_after_each2 }, 3, "child_after_each" );

    is_deeply(
        $self->{ order_before_each },
        [ 1, 2, 3 ],
        "before_each order"
    );
    is_deeply(
        $self->{ order_before_all },
        [ 1, 2, 3 ],
        "before_all order"
    );
    is_deeply(
        $self->{ order_after_each },
        [ 3, 2, 1 ],
        "after_each order"
    );
    is_deeply(
        $self->{ order_after_all },
        [ 3, 2, 1 ],
        "after_all order"
    );

    is( $self->{ no_ba }, 1, "no_ba ran" );
    is( $self->{ empty }, 1, "empty ran" );
    is( $self->{ only_after_all }, 1, "Ran after_all" );
    is( $self->{ only_after_each }, 1, "Ran after_each" );
};

1;
