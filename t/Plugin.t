#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Suite::TestHelper;

my $CLASS;

BEGIN {
    $CLASS = 'Test::Suite::Plugin';
    real_tests { use_ok( $CLASS, 'no_import' ) };

    {
        package Test::Suite::Plugin::A;
        use strict;
        use warnings;

        use Test::Suite::Plugin;

        tester a => sub { 'a' };

        sub _a { 'a' }

        tester deep_test => sub {
            my ( $num, $line, @extra ) = @_;
            ( my $p, my $f, $$line ) = caller(1);
            my @out = _recurse( $num, @extra );
            return (@out);
        };

        tester time_this => sub {
            sleep 2;
            return ( 1, "finished" );
        };

        tester do_sub => sub(&;$) { ($_[0]->() || undef, $_[1]) };

        tester extended => ( code => 'run_extended' );
        sub run_extended { 'extended' }

        tester 'light';
        sub _light { 'light' }

        tester code_inline => ( code => sub { 'code inline' });

        tester complex => (
            min_args => 1,
            max_args => 12,
            checks => [ undef, Ref, HashRef, ArrayRef, RegexpRef, CodeRef, Str, Int, Any, Undef, Num ],
            code => sub { 1, "Ignored" },
        );

        tester complex2 => (
            min_args => 1,
            max_args => 3,
            checks => { 2 => HashRef },
            code => sub { 1, "Ignored" },
        );

        util my_diag => sub { return $_[0] };

        sub _recurse {
            my ( $num, @other ) = @_;
            return _recurse( --$num, @other ) if $num;
            return @other;
        }

        package MyPackage;
        use strict;
        use warnings;
    }
}

real_tests {
    ok( !MyPackage->can($_), "MyPackage cannot $_" ) for qw/a _a/;
    Test::Suite::Plugin::A->export_to( 'MyPackage' );
    ok( !MyPackage->can($_), "MyPackage still cannot $_" ) for qw/_a/;
    can_ok( 'MyPackage', 'a' );
    is( MyPackage->a, 'a', "Correct result" );
};

real_tests {
    package main::2;
    use strict;
    use warnings;
    use Test::More;
    use Test::Exception::LessClever;
    use Test::Suite::TestHelper;

    BEGIN {
        Test::Suite::Plugin::A->export_to( __PACKAGE__ );
    }

    results( 1 );
    my @lines;
    deep_test( 10, \$lines[0], 1, "caller at 10" );
    deep_test( 5,  \$lines[1], 0, "caller at 5", "Got 0 not 1", "More debug" );
    deep_test( 16, \$lines[2],  1, "caller at 16" );
    is_deeply(
        results(),
        [
            {
                result => 1,
                name => "caller at 10",
                package => __PACKAGE__,
                filename => __FILE__,
                line => $lines[0],
                time => results()->[0]->{ 'time' },
                debug => [],
            },
            {
                result => 0,
                name => "caller at 5",
                package => __PACKAGE__,
                filename => __FILE__,
                line => $lines[1],
                time => results()->[1]->{ 'time' },
                debug => [ "Got 0 not 1", "More debug" ],
            },
            {
                result => 1,
                name => "caller at 16",
                package => __PACKAGE__,
                filename => __FILE__,
                line => $lines[2],
                time => results()->[2]->{ 'time' },
                debug => [],
            },
        ],
        "Results were correct and had proper package, file, and line number"
    );

    time_this();
    is_deeply(
        results()->[-1],
        {
            result => 1,
            name => "finished",
            package => __PACKAGE__,
            filename => __FILE__,
            line => results()->[-1]->{ 'line' }, #Tested elsware
            time => results()->[-1]->{ 'time' }, #Test this later
            debug => [],
        },
        "New result"
    );
    ok( results()->[-1]->{ 'time' } > 1, "took at least 1 second" );
    ok( results()->[-1]->{ 'time' } < 4, "took less than 4 seconds" );

    ok(( do_sub { 1 } "Name" ), "proto worked" );
    is_deeply(
        results()->[-1],
        {
            result => 1,
            name => "Name",
            package => __PACKAGE__,
            filename => __FILE__,
            line => results()->[-1]->{ 'line' }, #Tested elsware
            time => results()->[-1]->{ 'time' }, #Test this later
            debug => [],
        },
        "Deep proto test"
    );
    ok(!( do_sub { 0 } "Name" ), "proto false" );
    is_deeply(
        results()->[-1],
        {
            result => 0,
            name => "Name",
            package => __PACKAGE__,
            filename => __FILE__,
            line => results()->[-1]->{ 'line' }, #Tested elsware
            time => results()->[-1]->{ 'time' }, #Test this later
            debug => [],
        },
        "Deep proto test"
    );
    ok(!( do_sub { } "Name" ), "proto undef" );
    is_deeply(
        results()->[-1],
        {
            result => 0,
            name => "Name",
            package => __PACKAGE__,
            filename => __FILE__,
            line => results()->[-1]->{ 'line' }, #Tested elsware
            time => results()->[-1]->{ 'time' }, #Test this later
            debug => [],
        },
        "Deep proto test"
    );

    extended();
    is( results()->[-1]->{result}, 'extended', "extended" );

    light();
    is( results()->[-1]->{result}, 'light', 'light' );

    code_inline();
    is( results()->[-1]->{result}, 'code inline', 'code inline' );

    my @warn;
    local $SIG{__WARN__} = sub { push @warn => @_ };

    throws_ok { complex(1 .. 20 ) }
              qr/Too many arguments for complex\(\) takes no more than 12, you gave 20/,
              "too many args";

    throws_ok { complex() }
              qr/Too few arguments for complex\(\) requires 1, you gave 0/,
              "too many args";

    lives_ok { complex( 1, \"", {}, [], qr//, sub {}, "", 1, 'bob', undef, 1.5 ) }
             "Correct arguments";

    # FIXME - use of \@warn as a consistant ref is evil.
    @warn = ();
    throws_ok { complex( 1, "", "", "", "", "", \@warn, "text", [], 1, "hi" )}
            qr/Type constraints did not pass/,
            "Incorrect args";

    is( @warn, 9, "Number of warnings" );
    is_deeply(
        [ sort map { my $x = $_; $x =~ s/^(.*at).*$/$1/sg; $x } @warn ],
        [ sort
          "'" . \@warn . "' did not pass type constraint 'Str' at",
          "'' did not pass type constraint 'ArrayRef' at",
          "'text' did not pass type constraint 'Int' at",
          "'1' did not pass type constraint 'Undef' at",
          "'' did not pass type constraint 'HashRef' at",
          "'' did not pass type constraint 'Ref' at",
          "'' did not pass type constraint 'RegexpRef' at",
          "'hi' did not pass type constraint 'Num' at",
          "'' did not pass type constraint 'CodeRef' at",
        ],
        "All the correct warnings"
    );

    @warn = ();
    ok( complex2(1), "complex2 runs" );
    throws_ok { complex2( 1, 'a', 'b' )}
              qr/Type constraints did not pass/,
              "Died";

    is_deeply(
        map { my $x = $_; $x =~ s/^(.*at).*$/$1/sg; $x } @warn,
        "'b' did not pass type constraint 'HashRef' at",
        "correct warning"
    );

    is( my_diag( 'a' ), 'a', "Util function test" );

};

done_testing;
