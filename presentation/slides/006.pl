





package TEST::MyTest;
use strict;
use warnings;
use Fennec;

# If the module specified is not installed all tests will be skipped
use_or_skip 'Module::Name';

# Traditional script style works fine
ok( 1, "Not grouped" );
is( 'a', 'a', "" );

#It is much better to put tests into parallelizable groups.
tests hello_world_group {
    my $self = shift;
    ok( 1, "Hello world" );
}

1;









