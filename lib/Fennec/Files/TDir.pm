package Fennec::Files::TDir;
use strict;
use warnings;

use Fennec::Files qw/add_to_wanted/;

add_to_wanted(
    'TDir',
    qr{/t/.+\.pm$},
    sub { my $file = shift; eval "require '$file'" || die( $@ )}
);

1;
