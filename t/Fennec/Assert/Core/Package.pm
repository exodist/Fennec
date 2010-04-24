package TEST::Fennec::Assert::Core::Package;
use strict;
use warnings;
use Fennec;

tests load => sub {
    require_ok( 'Fennec::Assert::Core::Package' );
};

1;
