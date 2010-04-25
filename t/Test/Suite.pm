package TEST::Test::Suite;
use strict;
use warnings;
use Test::Suite;

tests 'aliased' => sub {
    can_ok( 'Test::Suite', 'import' );
    is(
        Test::Suite->can('import'),
        Fennec->can('import'),
        "Alias to Fennec"
    );
};

1;
