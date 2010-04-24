package TEST::Fennec::Assert::TBCore::Exception;
use strict;
use warnings;
use Fennec;

my $skip = eval "require Test::Exception; 1"
    ? undef
    : 'Test::Exception is not installed';

tests load => (
    skip => $skip,
    method => sub {
        require_ok( 'Fennec::Assert::TBCore::Exception' );
    },
);

1;
