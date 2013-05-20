use Fennec::Declare;

describe subsystemA {
    before_all initialize => sub { ... };

    before_each reset => sub { ... };

    tests methodA => sub { ... };
    tests methodB => sub { ... };

    after_each record => sub { ... };

    after_all deinitialize => sub { ... };
}

describe subsystemB {
    case is_cold    => sub { ... };
    case is_warm    => sub { ... };
    case is_unknown => sub { ... };

    tests will_not_shatter => sub { ... };
    tests will_not_melt    => sub { ... };
}

done_testing sub {
    ok( 1, "This runs last" );
};
