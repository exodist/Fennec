









sub setup_my_setup {
    print "methods prefixed by setup_ will be run before tests defined as methods.";
}

sub test_method_as_test_by_prefix {
    ok( 1, "methods prefixed by test_ will be run as method." );
}

sub teardown_my_teardown {
    print "method prefixed by teardown_ will be run after tests defined as methods."
}













