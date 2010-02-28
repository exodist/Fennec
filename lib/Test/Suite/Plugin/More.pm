package Test::Suite::Plugin::More;
use strict;
use warnings;

use Test::Suite::Plugin;
use Test::Suite::TestBuilderImposter;
use Test::Builder;
use Carp;

our @SUBS;
BEGIN {
    @SUBS = qw/ is isnt like unlike cmp_ok is_deeply can_ok isa_ok /;
}

use Test::More import => \@SUBS;

tester $_ => $_ for @SUBS;
util diag => sub { Test::Suite->diag( @_ ) };
util todo => sub(&$) {
    my ( $code, $todo ) = @_;
    local $Test::Suite::Plugin::TODO = $todo;
    $code->();
};

1;
