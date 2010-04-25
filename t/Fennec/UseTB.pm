package TEST::Fennec::UseTB;
use strict;
use warnings;
use Fennec asserts => [ 'Interceptor' ];

use_or_skip Test::More;

tests 'using Test::More asserts' => sub {
    ok( 1, "ok" );
    is( 1, 1, "is" );
};

tests 'capture Test::More asserts' => sub {
    my $pass = capture {
        ok( 1, "ok pass" );
        is( 1, 1, "is pass" );
        is_deeply( {}, {}, 'deeply pass' );
    };
    my $fail = capture {
        ok( 0, "ok fail" );
        is( 1, 2, "is fail" );
        is_deeply( {}, [], "deeply fail" );
    };
    ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. @$pass - 1;
    ok( !$fail->[$_]->pass, "$_ failed" )
        for grep { $fail->[$_]->isa( 'Fennec::Output::Result' ) }
            0 .. @$fail - 1;
};

1;
