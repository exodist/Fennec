package Fennec::File::Module;
use strict;
use warnings;

use base 'Fennec::File';

sub valid_file {
    my $class = shift;
    my ( $file ) = @_;
    return $file =~ m/\.pm$/
        ? 1
        : 0;
}

sub load_file {
    my $class = shift;
    my ( $file ) = @_;
    require $file;
}

sub paths {
    return qw{ t }
}

1;
