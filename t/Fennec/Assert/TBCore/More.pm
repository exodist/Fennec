package TEST::Fennec::Assert::TBCore::More;
use strict;
use warnings;
use Fennec;

my $skip = eval "require Test::More; 1"
    ? undef
    : 'Test::More is not installed';

tests load => (
    skip => $skip,
    method => sub {
        require_ok( 'Fennec::Assert::TBCore::More' );
    },
);

1;
