#!/usr/bin/perl;
package TEST::Standalone;
use strict;
use warnings;
use Fennec standalone => {};

use Fennec::Runner;
use Data::Dumper;
start;

sub Fennec {
    my $class = shift;

    tests hello_world => sub {
        my $self = shift;
        print STDERR "Were here!\n";
        ok( 1, "Hello world" );
        print STDERR "Were Done!\n";
    };
}

1;
