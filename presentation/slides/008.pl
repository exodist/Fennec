




# Compare:

    # Group A
    #######
    ok( 1, "1 is true!" );
    ok( 2, "2 is too!" );
    ######

    # VS

    tests 'Group A' {
        ok( 1, "1 is true!" );
        ok( 2, "2 is too!" );
    }

__END__

 * Usually you group similar tests together anyway, why not isolate them?

 * Doing this also allows you to run groups in parallel

 * You can also run only the group on which you are currently working.







