#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception::LessClever;
use Test::Builder::Tester;
use Fennec::TestHelper;

my $CLASS = 'Fennec::Tester';

real_tests {
    use_ok( $CLASS );
    can_ok( $CLASS, qw/no_load bad_files ignore inline case set _config/);

    my $one = $CLASS->new( files => [], _config => 1 );
    isa_ok( $one, $CLASS );

    ok( !$one->no_load, "accessor not set" );
    ok( $one->no_load(1), "setting accessor" );
    is( $one->no_load(), 1, "accessor was set" );

    delete $one->{ _config };
    $one->{ root } = 't/fakeroots/config/';
    ok( !$one->{ a }, "a not true" );
    $one->_load_config;
    is( $one->{a}, 'a', "a was set" );
    is( $one->{b}, 'b', "b was set" );

    ok( !$one->_looks_like_root( 't/fakeroots/not' ), "doesn't look like root" );
    ok( !$one->_looks_like_root( 't/fakeroots/no_exist' ), "doesn't look like root (doesn't exist)" );

    {
        my $CWD;
        no warnings qw/redefine once/;
        local *Fennec::Tester::cwd = sub { my $out = $CWD; undef( $CWD ); return $out };
        for (map { "t/fakeroots/$_" } qw{build config install t_lib testpl with_ts }) {
            $CWD = $_;
            delete $one->{ root };
            is( $one->root, $_, "Found proper root." );
        }
        $CWD = "t/fakeroots/config/depth";
        delete $one->{ root };
        is( $one->root, "t/fakeroots/config", "Root from depth" );
        $CWD = undef;
        is( $one->root, "t/fakeroots/config", 'cached root' );
    }

    $one->{ root } = 't/fakeroots/example';
    $one->{ ignore } = [ qr/Ignore/i ];
    delete $one->{ files };
    is_deeply(
        $one->files,
        [ qw{ t/fakeroots/example/ts/FindMe.pm }],
        "Files w/o inline"
    );

    delete $one->{ files };
    $one->inline(1);
    is_deeply(
        [ sort @{ $one->files }],
        [ sort qw{
            t/fakeroots/example/lib/MightFindMe.pm
            t/fakeroots/example/ts/FindMe.pm
        }],
        "Files w/ inline"
    );

    $one->{files} = [ 't/fakeroots/example/good.pm' ];
    lives_ok { $one->_load_files } "No problems with _load_files good";
    ok( !@{ $one->bad_files }, "No bad files" );

    $one->{files} = [ 't/fakeroots/example/bad.pm' ];
    lives_ok { $one->_load_files } "Tried to load bad file";
    ok( @{ $one->bad_files }, "bad file" );
    like(
        $one->bad_files->[0]->[1],
        qr/bad\.pm did not return a true value/,
        "got error"
    );

    {
        my $load;
        my @errors;
        no warnings qw{once redefine};
        *Fennec::Tester::failures = sub { @errors };
        *Fennec::Tester::_load_files = sub { $load++ };

        $one = $CLASS->get;
        $one->is_running(undef);
        $one->bad_files([]);
        $one->no_load(0);
        ok( $one->run, "ran" );
        ok( $load, "loaded files" );

        $load = 0;
        @errors = (1);
        $one->no_load(1);
        $one->is_running(undef);
        ok( !$one->run, "ran w/ errors" );
        ok( !$load, "did not load files" );

        $load = 0;
        @errors = ();
        $one->bad_files([['a', 'its a' ]]);
        $one->is_running(undef);
        ok( !$one->run, "ran w/ errors" );
        ok( !$load, "did not load files" );
    }

    my @results;
    {
        no warnings 'redefine';
        *Fennec::Tester::_handle_result = sub { shift and push @results => @_ };
    }

    Fennec::Tester->_handle_result( { a => 'a' } );
    is_deeply( \@results, [ { a => 'a' } ], "Saving results" );
    @results = ();

    $one = $CLASS->new();
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

done_testing();
