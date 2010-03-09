package Fennec::Files::Offset;
use strict;
use warnings;

use Fennec::Files qw/add_to_wanted/;

add_to_wanted(
    'Offset',
    qr{/lib(/TEST|/.*/TEST)/.+\.pm$},
    sub { my $file = shift; eval "require '$file'" || die( $@ )}
);

1;
