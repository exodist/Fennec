#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Object::Quick qw/obj method/;

my @output;

my $CLASS = 'Fennec::Handler::TAP';
use_ok( $CLASS );
ok( my $one = $CLASS->new( output => sub { push @output => @_ }), "Created" );
isa_ok( $one, $CLASS );

is( $one->count, "0001", "Start counter" );
is( $one->count, "0002", "More counter" );
is( $one->count, "0003", "Yet more counter" );
ok( $one->finish, "Finished" );
is( shift( @output ), '1..3', "Plan" );
$one->{ count } = 10000;
is( $one->count, "10000", "counter 10000+" );
delete $one->{ count };

$one->diag( 'a', 'b', 'c' ), "diag";
is_deeply(
    \@output,
    [ '# a', '# b', '# c' ],
    "Diag output"
);

@output = ();
$one->result( obj(
    result => 1,
    name => 'test a',
    diag => undef,
    line => 1,
    file => 'fake',
    skip => undef,
    todo => undef,
    benchmark => [ 5678.3245 ],
));
is_deeply(
    \@output,
    [ 'ok 0001 - [5678.32] test a' ],
    "ok result, no diag"
);

@output = ();
$one->result( obj(
    result => 0,
    name => 'test b',
    diag => [ 'help message' ],
    line => 1,
    file => 'fake',
    case => obj( name => 'case a' ),
    set => obj( name => 'set a' ),
    todo => undef,
    skip => undef,
    benchmark => undef,
));
is_deeply(
    \@output,
    [
        'not ok 0002 - [  N/A  ] test b',
        "# Test failure at fake line 1",
        "#     case: case a",
        "#     set: set a",
        "# help message"
    ],
    "not ok result, with diag"
);

@output = ();
$one->result( obj(
    result => 0,
    name => 'test c',
    diag => [ 'help message' ],
    line => 1,
    file => 'fake',
    case => obj( name => 'case a' ),
    set => obj( name => 'set a' ),
    todo => "XXX",
    skip => undef,
    benchmark => undef,
));
is_deeply(
    \@output,
    [
        'not ok 0003 - [  N/A  ] test c # TODO XXX',
        "# help message"
    ],
    "not ok result, with todo"
);

@output = ();
$one->result( obj(
    result => 0,
    name => 'test d',
    diag => [ 'help message' ],
    line => 1,
    file => 'fake',
    case => obj( name => 'case a' ),
    set => obj( name => 'set a' ),
    todo => undef,
    skip => "XXX",
    benchmark => undef,
));
is_deeply(
    \@output,
    [
        'ok 0004 - [  N/A  ] test d # SKIP XXX',
        "# help message"
    ],
    "not ok result, with skip"
);

@output = ();
$one->result( obj(
    result => 1,
    name => 'test a',
    diag => undef,
    line => 1,
    file => 'fake',
    skip => undef,
    todo => undef,
    benchmark => [ 8.3245 ],
));
is_deeply(
    \@output,
    [ 'ok 0005 - [   8.32] test a' ],
    "ok result, no diag"
);

done_testing();
