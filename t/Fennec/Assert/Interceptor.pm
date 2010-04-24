package TEST::Fennec::Assert::Interceptor;
use strict;
use warnings;
use Fennec;

tests load => sub {
    require_ok( 'Fennec::Assert::Interceptor' );
};

1;
