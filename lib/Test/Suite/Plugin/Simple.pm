package Test::Suite::Plugin::Simple;
use strict;
use warnings;

use Test::Suite::Plugin;

tester ok => (
    min_args => 1,
    max_args => 2,
    code => sub {
        my ( $result, $name ) = @_;
        return ( $result ? 1 : 0, $name );
    },
);

1;
