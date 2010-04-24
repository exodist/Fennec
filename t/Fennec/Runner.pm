package TEST::Fennec::Runner;
use strict;
use warnings;
use Fennec;

tests load => sub {
    require_ok( 'Fennec::Runner' );
};

1;
