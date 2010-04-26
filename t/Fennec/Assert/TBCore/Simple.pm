package TEST::Fennec::Assert::TBCore::Simple;
use strict;
use warnings;
use Fennec;

require_or_skip Test::Simple;

tests load => sub {
    require_ok( 'Fennec::Assert::TBCore::Simple' );
};

1;
