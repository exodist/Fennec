package TEST::Fennec::Assert::TBCore::Warn;
use strict;
use warnings;
use Fennec;

my $skip = eval "require Test::Warn; 1"
    ? undef
    : 'Test::Warn is not installed';

tests load => (
    skip => $skip,
    method => sub {
        require_ok( 'Fennec::Assert::TBCore::Warn' );
    },
);

1;
