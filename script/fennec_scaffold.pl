#!/usr/bin/perl
use strict;
use warnings;

use File::Find;
use File::Path qw(make_path);

our %MODULES;

find(
    sub {
        my $name = $File::Find::name;
        return unless $name =~ m/\.pm$/;
        $MODULES{ $name } = [ $File::Find::dir, $_ ];
    },
    './lib'
);

for my $item ( values %MODULES ) {
    $item->[0] =~ s|^\./lib|./t|;
    my $test = join( '/', @$item );
    next if -e $test;
    mktest( $item, $test );
}

sub mktest {
    my ( $item, $test ) = @_;
    my $package = file_to_package( $test );
    make_path( $item->[0] );
    open( my $FILE, '>', $test ) || die( "Error creating file '$test': $!" );
    print $FILE <<EOT;
package TEST\::$package;
use strict;
use warnings;
use Fennec;

tests load => sub {
    require_ok( '$package' );
};

1;
EOT
    close( $FILE )
}

sub file_to_package {
    my ( $file ) = @_;
    my $out = $file;
    $out =~ s|^(.*/)?t/||g;
    $out =~ s|\.pm$||g;
    $out =~ s|/+|::|g;
    return $out;
}
