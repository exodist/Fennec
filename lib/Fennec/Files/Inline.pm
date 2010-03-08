package Fennec::Files::Inline;
use strict;
use warnings;

use Fennec::Files qw/add_to_wanted/;

add_to_wanted(
    'Inline',
    qr{/lib/.+\.pm$},
    sub { my $file = shift; eval "require $file" || die( $@ )}
);

1;
