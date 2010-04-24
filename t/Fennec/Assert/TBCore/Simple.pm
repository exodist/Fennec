package TEST::Fennec::Assert::TBCore::Simple;
use strict;
use warnings;
use Fennec;

my $skip = eval "require Test::Simple; 1"
    ? undef
    : 'Test::Simple is not installed';

tests load => (
    skip => $skip,
    method => sub {
        require_ok( 'Fennec::Assert::TBCore::Simple' );
    },
);

1;
