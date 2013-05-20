use Fennec::Declare parallel => 1;

ok( 1, "1 is true" );

describe outer_b {
    my $init  = 0;
    my $state = 0;
    my $bleed = 100;

    before_all initialize { $init += 1 }

    case case_1 { $state += 1 }
    case case_2 { $state += 2 }

    before_each bleed { $bleed -= 100 }

    tests inner_b {
        ok( $state && $state < 3,  "\$state is valid" );
        is( $init, 1, "Initialized" );
        ok( !$bleed, "not bleeding" );
        $bleed += 5;
    }

    after_each clear { $state = 0; $init = 0    }
    after_all  check { die unless $bleed == 100 }
}

done_testing sub {
    ok( 2, "2 is true" );
};
