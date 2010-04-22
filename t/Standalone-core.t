#!/usr/bin/perl;
package TEST::StandaloneCore;
use strict;
use warnings;
use Fennec::Standalone;

tests hello_world_group => sub {
    my $self = shift;
    ok( 1, "Hello world" );
};

finish;

1;
