package Fennec::Assert::Core::More;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::More;

our @LIST = qw/is isnt like unlike cmp_ok can_ok isa_ok new_ok is_deeply/;

for my $name ( @LIST ) {
    no strict 'refs';
    next unless Test::More->can( $name );
    tester $name => tb_wrapper \&{ 'Test::More::' . $name };
}

1;
