#!/usr/bin/perl
package TEST::Mock;
use strict;
use warnings;

use Fennec;

BEGIN {
    require_ok( 'Mock::Quick' );
    Mock::Quick->import();
    can_ok( __PACKAGE__, qw/ qobj qclass qtakeover qclear qmeth /);

    package Foo;
}

tests object => sub {
    is( qclear(), \$Mock::Quick::Util::CLEAR, "clear returns the clear reference" );

    my $one = qobj( foo => 'bar' );
    isa_ok( $one, 'Mock::Quick::Object' );
    is( $one->foo, 'bar', "created properly" );

    my $two = qmeth { 'vm' };
    isa_ok( $two, 'Mock::Quick::Method' );
    is( $two->(), "vm", "virtual method" );

    my $three = qobj( foo => qmeth { 'bar' } );
    is( $three->foo, 'bar', "ran virtual method" );
    $three->foo( qclear() );
    ok( !$three->foo, "cleared" );
};

tests class => sub {
    my $one = qclass( foo => 'bar' );
    isa_ok( $one, 'Mock::Quick::Class' );
    can_ok( $one->package, 'foo' );

    my $two = qtakeover( 'Foo' );
    isa_ok( $two, 'Mock::Quick::Class' );
    is( $two->package, 'Foo', "took over Foo" );
};

1;
