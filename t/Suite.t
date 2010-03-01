#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;
use Test::Builder::Tester;
use Test::Suite::TestHelper;

my $CLASS;

#{{{ Test _handle_result before we override it.
BEGIN {
    $CLASS = 'Test::Suite';
    require Test::Suite;

    test_out( "ok 1" );
    $CLASS->_handle_result({ result => 1 });
    test_out( "ok 2 - NAME" );
    $CLASS->_handle_result({ result => 1, name => 'NAME' });

    test_out( "not ok 3 - NAME" );
    test_fail(+4);
    #test_diag( "\tTest failed in file filename\t\non line 1" );
    test_diag( "a" );
    test_diag( "b" );
    $CLASS->_handle_result({
        result => 0,
        name => 'NAME',
        filename => 'filename',
        line => '1',
        debug => [ 'a', 'b' ],
    });

    test_diag( "xxx" );
    $CLASS->_handle_result({ diag => "xxx" });

    test_test( "_handle_result works" );
}
#}}}

my @results;
{
    no warnings 'redefine';
    *Test::Suite::_handle_result = sub { shift and push @results => @_ };
}

real_tests {
    Test::Suite->_handle_result( 'a' );
    is_deeply( \@results, [ 'a' ], "Saving results" );
    @results = ();

    my $one = $CLASS->new();
    is( $one, $CLASS->new(), "singleton" );
    is( $one, $CLASS->get(), "singleton - get" );
    is( $one->parent_pid, $$, "Parent PID" );
    is( $one->pid, $$, "PID" );
    isa_ok( $one->{ socket }, 'IO::Socket::UNIX' );
    like( $one->_socket_file, qr{./\.test-suite\.$$\.....$}, "Socket file" );

    my $test = bless( {}, 'Some::Package' );
    $one->add_test( $test );
    is( $one->get_test( 'Some::Package' ), $test, "Got test" );

    throws_ok { $one->add_test( $test )}
              qr/Some::Package has already been added as a test/,
              "No overide";

    ok( $one->is_parent, "is parent" );
};

{
    package My::LoadIt;
    use strict;
    use warnings;
    BEGIN {
        $INC{ 'My/LoadIt.pm' } = __FILE__;
        our @EXPORT = qw/return_a/;
        our @EXPORT_OK = qw/return_b/;
    }
    use base 'Exporter';

    sub return_a { 'a' };
    sub return_b { 'b' };

    package My::TestA;
    use strict;
    use warnings;
    use Test::Suite testing => 'My::LoadIt';

    package My::TestB;
    use strict;
    use warnings;
    use Test::Suite testing => 'My::LoadIt',
                    import_args => [ 'return_b' ];
}

real_tests {
    throws_ok { package My::Test::Die; Test::Suite->import( testing => 'Fake::Package::Name' )}
              qr{Can't locate Fake/Package/Name\.pm},
              "Dies when testing invalid or broken package";

    isa_ok( 'My::TestA', 'Test::Suite::TestBase' );
    can_ok( 'My::TestA', qw/ok throws_ok is_deeply warning_is return_a test_set test_case/ );

    isa_ok( 'My::TestB', 'Test::Suite::TestBase' );
    can_ok( 'My::TestB', qw/ok throws_ok is_deeply warning_is return_b test_set test_case/ );
};

done_testing;
