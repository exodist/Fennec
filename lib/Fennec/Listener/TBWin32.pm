package Fennec::Listener::TBWin32;
use strict;
use warnings;

use Test::Builder;
push @Test::Builder::ISA => 'Fennec::Listener';

sub new { Test::Builder->new }

sub Test::Builder::terminate {
    Test::Builder->new->done_testing();
}

1;
