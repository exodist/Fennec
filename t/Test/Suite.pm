package TEST::Test::Suite;
use strict;
use warnings;
use Fennec;

tests load => sub {
    require_ok( 'Test::Suite' );
};

1;
