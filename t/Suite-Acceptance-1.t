#!/usr/bin/perl
use strict;
use warnings;

use Test::Suite random => 1;

test_case 'a' => sub {1};
test_case 'b' => sub {1};
test_case 'c' => sub {1};
test_case 'd' => sub {1};

test_set set_a => sub {
    ok( 1, "Simple ok set a" );
};

test_set set_b => sub {
    ok( 1, "Simple ok set b" );
};

test_set set_c => sub {
    ok( 1, "Simple ok set c" );
};

test_set set_d => sub {
    ok( 1, "Simple ok set d" );
};

test_set set_e => sub {
    is_deeply( { a => 'a' }, { a => 'a' }, "is_deeply" );
};

require Test::Suite::Tester;
Test::Suite::Tester->run();

1;
