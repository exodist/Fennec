#!/usr/bin/perl
package Fennec::Test::SelfRunning;
use strict;
use warnings;

use Fennec;

my $parent = $$;
my $num;
#for ( 1 .. 3 ) {
#    $num++;
#    fork();
#    last unless $$ == $parent;
#}
$num = 0 if $parent == $$;

can_ok( __PACKAGE__, 'tests' );

TODO: {
    local $TODO = "XXX";
    ok( 0, "pid: $$" );
}

exit 0 unless $$ == $parent;

#tests is_in_runner => sub {
#    my $self = shift;
#    ok( 1 );
#    ok( 1, "A" );
#    ok( 1, "b" );
#    ok( 1, "c" );
#    ok( 0, "blah" );
#    ok( 0, "blah2" );
#    {
#        local $TODO = "uhg";
#        is( 1, 2, "hup" );
#    }
#};

1;
