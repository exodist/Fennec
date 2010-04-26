package TEST::Fennec::Assert::TBCore::More;
use strict;
use warnings;
use Fennec;

require_or_skip Test::More;

tests load => sub {
    require_ok( 'Fennec::Assert::TBCore::More' );
};

1;
