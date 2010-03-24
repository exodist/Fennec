package TEST::Fennec;
use strict;
use warnings;

use Fennec asserts => [ 'Core', 'Interceptor' ];

tests hello_world_group => sub {
    my $self = shift;
    ok( 1, "Hello world" );
    diag "Hello Message";

    my $output = capture {
        ok( 0, "Should fail" );
    };
    ok( !$output->[0]->pass, "intercepted a failed test" );
};

1;
