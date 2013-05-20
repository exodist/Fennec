use Fennec::Declare;

describe subsystemA {
    before_all initialize { ... }

    before_each reset { ... }

    tests methodA { ... }
    tests methodB { ... }

    after_each record { ... }

    after_all deinitialize { ... }
}

describe subsystemB {
    case is_cold    { ... }
    case is_warm    { ... }
    case is_unknown { ... }

    tests will_not_shatter { ... }
    tests will_not_melt    { ... }
}

done_testing sub {
    ok( 1, "This runs last" );
};
