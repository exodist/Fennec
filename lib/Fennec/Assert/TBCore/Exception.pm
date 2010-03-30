package Fennec::Assert::TBCore::Exception;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::Exception;

our @LIST = qw/ throws_ok dies_ok lives_ok lives_and /;

for my $name ( @LIST ) {
    no strict 'refs';
    next unless Test::Exception->can( $name );
    tester $name => tb_wrapper \&{ 'Test::Exception::' . $name };
}

1;

