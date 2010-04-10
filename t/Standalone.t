#!/usr/bin/perl;
package TEST::Standalone;
use strict;
use warnings;
use Fennec standalone => {},
           asserts    => [ 'Core', 'Interceptor' ];

use Fennec::Runner;
use Data::Dumper;
use Carp qw/cluck/;

start;

sub Fennec {
    my $class = shift;

    tests hello_world_group => sub {
        my $self = shift;
        ok( 1, "Hello world" );
        my $result = capture {
            diag "Hello Message";
        };
        is( $result->[0]->stderr->[0], "Hello Message", "Got diag" );

        my $output = capture {
            ok( 0, "Should fail" );
        };
        ok( !$output->[0]->pass, "intercepted a failed test" );
    };
}

1;
