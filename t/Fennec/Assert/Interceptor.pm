package TEST::Fennec::Assert::Interceptor;
use strict;
use warnings;
use Fennec;

tests load => sub {
    require_ok( 'Fennec::Assert::Interceptor' );
};

tests declare {
    my $results = capture {
        ok( 1, "one" );
        ok( 0, "zero" );
    }

    is( @$results, 2, "capture works w/o semicolon" );
}

1;
