#!/usr/bin/perl;
package TEST::Standalone;
use strict;
use warnings;
use Fennec standalone => {};

use Fennec::Runner;
use Data::Dumper;
print Dumper( Runner->handler );

start;

sub Fennec {
    my $class = shift;

    tests hello_world => sub {
        my $self = shift;
        ok( 1, "Hello world" );
    };
}

1;
