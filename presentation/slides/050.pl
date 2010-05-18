





tests like {
    my $pass = capture {
        like( 'abcd', qr/^abcd$/, 'full' );
        like( 'efgh', qr/^efgh/, 'start' );
        like( 'ijkl', qr/ijkl$/, 'end' );
        like( 'abcd', 'abcd', 'string-not-regex' );
    };

    ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. ( @$pass - 1 );

    my $fail = capture {
        like( 'abcd', qr/efgh/, 'fail' );
        like( 'apple', qr/pear/, 'fail 2' );
    };

    ok( !$fail->[$_]->pass, "$_ failed" ) for 0 .. ( @$fail - 1 );
    is( $fail->[0]->stderr->[0], "'abcd' does not match (?-xism:efgh)", "Correct error" );
    is( $fail->[1]->stderr->[0], "'apple' does not match (?-xism:pear)", "Correct error" );
}









