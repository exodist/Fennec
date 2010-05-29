







tests Simple {
    ok( 1, "Passing" );
    ok( 0, "Failing" );
}




tests 'Complicated' => (
    method => sub { ... },
    # Only report a failure
    no_result => 1,
    # Skip or todo an entire group
    skip => $reason,
    todo => $reason,
);










