package TEST::Fennec::Assert::TBCore;
use strict;
use warnings;
use Fennec;

require_or_skip Test::Builder;
require_or_skip Test::More;
require_or_skip Test::Simple;
require_or_skip Test::Warn;
require_or_skip Test::Exception;

tests load => sub {
    require_ok( 'Fennec::Assert::TBCore' );
};

1;
