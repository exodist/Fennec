#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Runner;
BEGIN {
    Fennec::Runner->new( file_types => [] );
}

package Test::GetItWorking;
use strict;
use warnings;
use Fennec testers => [ 'TestResults' ];

test_set a => sub {
    ok( 1, "Hello world" );
    diag( "Hello Diag" );
};

Fennec::Runner->get->run;
