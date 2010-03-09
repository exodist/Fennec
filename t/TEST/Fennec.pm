package TEST::Fennec;
use strict;
use warnings;
use Fennec testers => [ 'TestResults' ];

test_case a => sub {
    ok( 1, "test in case" );
};

sub case_b {
    ok( 1, "case from sub" );
}

test_set a => sub {
    ok( 1, "Hello world" );
    diag( "Hello Diag" );
};

sub set_b {
    ok( 1, "set from sub" );
    ok( Fennec::Runner->get->is_parent, "Still in parent" );
}

test_set 'fork' => (
    force_fork => 1,
    method => sub {
        ok( !Fennec::Runner->get->is_parent, "we forked" );
    },
);

1;
