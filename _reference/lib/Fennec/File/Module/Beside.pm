package Fennec::File::Module::Beside;
use strict;
use warnings;

use base 'Fennec::File::Module';

sub valid_file {
    my $class = shift;
    my ( $file ) = @_;
    return $file =~ m{TEST/[^/]+\.pm$}
        ? 1
        : 0;
}

sub paths {
    return qw{ lib }
}

1;

