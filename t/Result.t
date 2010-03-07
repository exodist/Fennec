#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Object::Quick '-all';

my $CLASS = 'Fennec::Result';
use_ok( $CLASS );

can_ok( $CLASS, qw/result name case set diag is_diag file line benchmark test/ );

ok(
    my $one = $CLASS->new(
        result    => 1,
        name      => 'a test',
        benchmark => [ 1, 1, 1, 1 ],
        case      => obj( name => 'case a', todo => 0, skip => 0 ),
        set       => obj( name => 'set a', todo => 0, skip => 0 ),
        file      => 'file.pm',
        line      => 12,
        test      => obj( a => 'a' ),
        diag      => [ 'a', 'b', 'c' ],
        is_diag   => 0,
    ),
    "Created one"
);

my $VAR1;
my $data = eval $one->serialize || die( $@ );
is_deeply(
    $data,
    {
        result     => 1,
        name       => 'a test',
        benchmark  => [ 1, 1, 1, 1 ],
        case_name  => 'case a',
        set_name   => 'set a',
        file       => 'file.pm',
        line       => 12,
        test_class => 'Object::Quick',
        diag       => [ 'a', 'b', 'c' ],
        is_diag    => 0,
        skip       => 0,
        todo       => 0,
    },
    "serialized"
);

sub Fennec::Runner::get {
    obj(
        get_test => method {
            obj(
                _cases => { 'case a' => obj( name => 'case a' )},
                _sets => { 'set a' => obj( name => 'set a' )},
            )
        }
    )
};

ok( my $two = $CLASS->deserialize( $one->serialize ), "Cycle" );

is_deeply(
    $two,
    {
        result     => 1,
        name       => 'a test',
        benchmark  => [ 1, 1, 1, 1 ],
        case       => obj( name => 'case a' ),
        set        => obj( name => 'set a' ),
        file       => 'file.pm',
        line       => 12,
        test       => obj(
            _cases => { 'case a' => obj( name => 'case a' )},
            _sets  => { 'set a'  => obj( name => 'set a' )},
        ),
        diag       => [ 'a', 'b', 'c' ],
        is_diag    => 0,
        skip       => 0,
        todo       => 0,
    },
    "Deserialized"
);

for my $item ( qw/todo skip/ ) {
    $one = bless({
        $item => "self $item",
        case => obj( $item => "case $item" ),
        set => obj( $item => "set $item" ),
    }, $CLASS);

    is( $one->$item, "self $item", "$item from self" );
    delete $one->{ $item };
    is( $one->$item, "set $item", "$item from set" );
    $one->set->$item( undef );
    is( $one->$item, "case $item", "$item from case" );
}

done_testing;
