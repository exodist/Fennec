#!/usr/bin/perl;
package TEST::StandaloneCore;
use strict;
use warnings;
use Fennec standalone => {};

use Fennec::Runner;
use Data::Dumper;
use Carp qw/cluck/;

start;

sub Fennec {
    my $class = shift;

    tests hello_world_group => sub {
        my $self = shift;
        ok( 1, "Hello world" );
    };
}

1;
