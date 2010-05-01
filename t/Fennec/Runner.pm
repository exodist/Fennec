package TEST::Fennec::Runner;
use strict;
use warnings;
use Fennec;

require_ok( 'Fennec::Runner' );

tests 'reap_callback' => sub {
    local *reap_callback = \&Fennec::Runner::_reap_callback;
    my $res = capture {
        reap_callback( 0, 1, 1 );
        reap_callback( 15 << 8, 1, 1 );
        reap_callback( 0, 1, -1 );
    };
    is( @$res, 2, "2 results" );
    ok( !$res->[0]->pass, "result 0 fail" );
    ok( !$res->[1]->pass, "result 1 fail" );
    is(
        $res->[0]->stderr->[0],
        "Child (1) exited with non-zero status(15)!",
        "non-zero exit"
    );
    is(
        $res->[1]->stderr->[0],
        "waitpid(1) returned -1!",
        "waitpid funkyness"
    );
};

1;
