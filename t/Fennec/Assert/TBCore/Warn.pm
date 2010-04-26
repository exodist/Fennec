package TEST::Fennec::Assert::TBCore::Warn;
use strict;
use warnings;
use Fennec;

require_or_skip Test::Warn;

tests load => sub {
    require_ok( 'Fennec::Assert::TBCore::Warn' );
};

1;
