#!/usr/bin/perl
package Fennec::Test::SelfRunning;
use strict;
use warnings;

use Fennec;

my $parent = $$;

tests hoo => sub {
    my $num;
    for ( 1 .. 3 ) {
        $num++;
        fork();
        last unless $$ == $parent;
    }
    $num = 0 if $parent == $$;

    can_ok( __PACKAGE__, 'tests' );

    exit 0 unless $$ == $parent;
};

tests foo => sub { ok( 1, 'bar' )};

describe boo => sub {
    case a => sub { print "a\n" };
    case b => sub { print "b\n" };
    tests c => sub { print "c\n" };
};

describe blah => sub {
    my $self = shift;
    isa_ok( $self, __PACKAGE__ );
    before_all xxx => sub { print "before all\n" };
    after_all  yyy => sub { print "after all\n" };
    tests insidex => sub { ok( 1, "xinside 1" )};

    before_each uhg => sub { print "before 1\n" };
    after_each uhg2 => sub { print "after 1\n" };
    tests insidey => sub { ok( 1, "yinside 1" )};

    tests die => sub { die "XXX" };
    tests die2 => sub {
        die "XXX"
    };

    describe blah2 => sub {
        before_each xuhg => sub { print "before 2\n" };
        after_each xuhg2 => sub { print "after 2\n" };
        tests xinside => sub { ok( 1, "xinside 2" )};
        tests yinside => sub { ok( 1, "yinside 2" )};
    };
};

1;
