package Fennec::Config;
use strict;
use warnings;

    my $conf_file = $root . "/.fennec";
    if ( -f $conf_file ) {
        $config = eval { require $conf_file }
            || croak( "Error loading config file: $@" );
        croak( "config file did not return a hashref" )
            unless ref( $config ) eq 'HASH';
    }

1;
