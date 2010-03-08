#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $CLASS = 'Fennec::Runner::Root';
use_ok( $CLASS );

my $one = $CLASS->new;

ok( !$one->_looks_like_root( 't/fakeroots/not' ), "doesn't look like root" );
ok( !$one->_looks_like_root( 't/fakeroots/no_exist' ), "doesn't look like root (doesn't exist)" );

{
    my $CWD;
    no warnings qw/redefine once/;
    local *Fennec::Runner::Root::cwd = sub { my $out = $CWD; undef( $CWD ); return $out };
    for (map { "t/fakeroots/$_" } qw{build config install t_lib testpl }) {
        $CWD = $_;
        $$one = "";
        is( $one->path, $_, "Found proper root." );
    }
    $CWD = "t/fakeroots/config/depth";
    $$one = "";
    is( $one->path, "t/fakeroots/config", "Root from depth" );
    $CWD = undef;
    is( $one->path, "t/fakeroots/config", 'cached root' );
}

done_testing;
