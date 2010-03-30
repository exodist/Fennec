package Fennec::Assert::TBCore::Simple;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::Simple;

our @LIST = qw/ok/;

for my $name ( @LIST ) {
    no strict 'refs';
    next unless Test::Simple->can( $name );
    tester $name => tb_wrapper \&{ 'Test::Simple::' . $name };
}

1;
