package TEST::Fennec::Assert::TBCore::Exception;
use strict;
use warnings;
use Fennec;

require_or_skip Test::Exception;

tests load => sub {
    require_ok( 'Fennec::Assert::TBCore::Exception' );
};

1;
