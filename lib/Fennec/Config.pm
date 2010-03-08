package Fennec::Config;
use strict;
use warnings;

use Fennec::Util qw/add_accessors/;

add_accessors qw/max_sets max_cases max_partitions max_files/;

our @FILES = ( "$ENV{HOME}/.fennec", "/etc/fennec" );

sub new {
    my $class = shift;
    my ($file) = @_;
    ($file) = grep { -f $_ } @FILES
        unless( $file );



}
    my $conf_file = $root . "/.fennec";
    if ( -f $conf_file ) {
        $config = eval { require $conf_file }
            || croak( "Error loading config file: $@" );
        croak( "config file did not return a hashref" )
            unless ref( $config ) eq 'HASH';
    }

1;
