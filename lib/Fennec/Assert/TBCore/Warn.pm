package Fennec::Assert::TBCore::Warn;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::Warn;

our @LIST = qw/warning_is warnings_are warning_like warnings_like warnings_exist/;

for my $name ( @LIST ) {
    no strict 'refs';
    next unless Test::Warn->can( $name );
    tester $name => tb_wrapper \&{ 'Test::Warn::' . $name };
}

1;
