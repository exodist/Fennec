#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;

my $CLASS = 'Test::Suite::TestBase';
use_ok( $CLASS );

throws_ok { my $one = $CLASS->new() }
          qr/$CLASS cannot not be instantiated/,
          "Cannot init base class";

{
    package My::Test;
    use strict;
    use warnings;
    use base 'Test::Suite::TestBase';

    sub case_CASE_FROM_SUB {1}
    sub set_SET_FROM_SUB {1}
    sub CaSe_CaSe_WiTh_CaPs {1}
    sub SeT_sEt_WiTh_CaPs {1}
}

$CLASS = 'My::Test';

ok(
    my $one = $CLASS->new(
        random => 1,
        parallel => 1,
        case_defaults => {},
        set_defaults => {},
        filename => 1,
    ),
    "New instance"
);
isa_ok( $one, 'Test::Suite::TestBase' );
isa_ok( $one, $CLASS );
is( $one, $CLASS->new, "singleton" );

is( $one->random, 1, "random()" );
is( $one->parallel, 1, "parallel()" );
is( $one->filename, 1, "filename()" );
is_deeply( $one->case_defaults, {}, "case_defaults" );
is_deeply( $one->set_defaults, {}, "set_defaults" );
is_deeply( $one->_cases, {}, "_cases" );
is_deeply( $one->_sets, {}, "_sets" );
ok( $one->_cases != $one->_cases({}), "Accessors" );
ok( $one->random(5) != 5, "Readers" );
can_ok( $one, 'set', 'case', '__find_subs' );

is_deeply( $one->_cases, {}, "No Cases yet." );
is_deeply( $one->_sets, {}, "No sets yet." );
ok( !$one->__find_subs, "havn't found subs yet" );
$one->_find_subs;
ok( $one->__find_subs, "found subs" );
is_deeply(
    [ map { $_->name } $one->cases ],
    [ sort qw/CASE_FROM_SUB CaSe_WiTh_CaPs/ ],
    "Found all cases"
);
is_deeply(
    [ map { $_->name } $one->sets ],
    [ sort qw/SET_FROM_SUB sEt_WiTh_CaPs/],
    "Found all sets"
);

throws_ok { $one->add_set( 'SET_FROM_SUB' )}
          qr/Set with name SET_FROM_SUB already exists/,
          "No duplicate sets";

throws_ok { $one->add_case( 'CASE_FROM_SUB' )}
          qr/Case with name CASE_FROM_SUB already exists/,
          "No duplicate cases";

ok(( $one->cases(1)), "We get results when testing with random" );
ok(( $one->sets(1)), "We get results when testing with random" );


our %RUNS;
{
    package My::Test2;
    use strict;
    use warnings;
    use base 'Test::Suite::TestBase';
    use Test::More;
    {
        no warnings 'once';
        *RUNS = %main::RUNS;
    }

    sub init {
        my $self = shift;
        ok( $self, "got self" );
        isa_ok( $self, __PACKAGE__ );
        $RUNS{ count }->{ init }++;
        push @{$RUNS{ as }} => [ $self->case, $self->set, 'init' ];
    }

    sub case_case_a {
        my $self = shift;
        ok( $self, "got self" );
        isa_ok( $self, __PACKAGE__ );
        $RUNS{ count }->{ case_a }++;
        push @{$RUNS{ as }} => [ $self->case->name, $self->set ];
    }

    sub case_case_b {
        my $self = shift;
        ok( $self, "got self" );
        isa_ok( $self, __PACKAGE__ );
        $RUNS{ count }->{ case_b }++;
        push @{$RUNS{ as }} => [ $self->case->name, $self->set ];
    }

    sub set_set_a {
        my $self = shift;
        ok( $self, "got self" );
        isa_ok( $self, __PACKAGE__ );
        $RUNS{ count }->{ set_a }++;
        push @{$RUNS{ as }} => [ $self->case->name, $self->set->name ];
    }

    sub set_set_b {
        my $self = shift;
        ok( $self, "got self" );
        isa_ok( $self, __PACKAGE__ );
        $RUNS{ count }->{ set_b }++;
        push @{$RUNS{ as }} => [ $self->case->name, $self->set->name ];
    }
}
$CLASS = 'My::Test2';
$one = $CLASS->new( random => 0 );
$one->run();
is_deeply(
    \%RUNS,
    {
        count => { init => 1, case_a => 1, case_b => 1, set_a => 2, set_b => 2 },
        as => [
            [ undef, undef, 'init' ],

            [ 'case_a', undef ],
            [ 'case_a', 'set_a' ],
            [ 'case_a', 'set_b' ],

            [ 'case_b', undef ],
            [ 'case_b', 'set_a' ],
            [ 'case_b', 'set_b' ],
        ]
    },
    "run() behaved as expected"
);

done_testing;
