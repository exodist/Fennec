








sub setup_my_setup {
    my $self = shift;
    print "methods prefixed by setup_ will be run before tests defined as methods.";
}

sub test_method_as_test_by_prefix {
    my $self = shift;
    ok( 1, "methods prefixed by test_ will be run as method." );
}

sub teardown_my_teardown {
    my $self = shift;
    print "method prefixed by teardown_ will be run after tests defined as methods."
}











