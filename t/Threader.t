#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;

my $CLASS = 'Fennec::Tester::Threader';
use_ok( $CLASS );

can_ok( $CLASS, qw/pid max_files max_partitions max_cases max_sets files partitions cases sets/);

ok( my $one = $CLASS->new( max_sets => 1 ), "Created one" );
isa_ok( $one, $CLASS );

sub Fennec::Tester::_sub_process_exit { exit };
sub Fennec::Tester::get { return $_[0] };

is( $one->pid, $$, "Stored pid" );
is_deeply(
    $one,
    {
        files           => [],
        partitions      => [],
        cases           => [],
        sets            => [],
        max_sets        => 1,
        pid             => $$,
    },
    "Built properly"
);

is( $one->tid_pid( 'sets', 1 ), undef, "No pid for tid 1" );
is( $one->tid_pid( 'sets', 1, 55 ), 55, "set pid for tid" );
is( $one->tid_pid( 'sets', 1 ), 55, "Has pid" );
is( $one->tid_pid( 'files', 2, 56 ), 56, "set pid for tid" );
is( $one->tid_pid( 'cases', 3, 57 ), 57, "set pid for tid" );

is_deeply( [sort $one->pids], [ 55, 56, 57 ], "Got pids" );

lives_ok {
    local $SIG{ ALRM } = sub { die("Cleanup took too long")};
    alarm 5;
    $one->cleanup;
    alarm 0;
} "cleanup";

lives_ok {
    local $SIG{ ALRM } = sub { die("xxx")};
    alarm 5;
    $one->{ files } = [ 1, 2, 3, 4 ];
    $one->get_tid( 'files', 4 );
    alarm 0;
} "wait on bad pid";

sub timed_fork {
    my ( $count ) = @_;
    my $pid = fork;
    return $pid if $pid;
    sleep $count;
    exit;
}

$one->{ files } = [];
is( $one->get_tid( 'files', 3 ), 1, "Get first available tid" );
$one->tid_pid( 'files', 1, timed_fork( 10 ) );
is( $one->get_tid( 'files', 3 ), 2, "Get first available tid" );
$one->tid_pid( 'files', 2, timed_fork( 10 ) );
is( $one->get_tid( 'files', 3 ), 3, "Get first available tid" );
$one->tid_pid( 'files', 3, timed_fork( 10 ) );

throws_ok {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 5;
    $one->get_tid( 'files', 3 );
    alarm 0;
} qr/alarm/,
  "Timed out";

lives_and {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 20;
    my $start = time;
    my $tid = $one->get_tid( 'files', 3 );
    ok( time - $start > 3, "was blocking" );
    ok( $tid, "Got tid after blocking" );
    alarm 0;
} "Subprocess did not exit";

$one->{ files } = [];
$one->{ max_files } = 3;

sleep 2;

lives_ok {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 5;
    $one->thread( 'file', sub { sleep $_[0] }, 15 );
    $one->thread( 'file', sub { sleep $_[0] }, 15 );
    $one->thread( 'file', sub { sleep $_[0] }, 15 );
    alarm 0;
} "3 processes w/o waiting" || diag $@;

throws_ok {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 5;
    $one->thread( 'file', sub { sleep $_[0] }, 1 );
    alarm 0
} qr/alarm/, "Blocked";

lives_and {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 30;
    my $start = time;
    $one->thread( 'file', sub { sleep $_[0] }, 1 );
    ok( 1, "Eventually got a tid" );
    ok( time - $start > 5, "Blocked a while" );
    alarm 0
} "Blocked";

$one->{ files } = [];
delete $one->{ max_files };

lives_and {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 5;
    $one->get_tid( 'files', 1 );
    alarm 0;
    ok( 1, "Not blocked" );
} "Not blocked";

throws_ok {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 5;
    $one->thread( 'file', sub { sleep $_[0] }, 10 );
    ok( ! @{ $one->files }, "no new pids" );
    alarm 0
} qr/alarm/, "Run w/o fork";

throws_ok {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 5;
    $one->thread( 'fork', sub { sleep $_[0] }, 10 );
    alarm 0
} qr/alarm/, "fork but wait";

lives_and {
    local $SIG{ ALRM } = sub { die("alarm")};
    alarm 15;
    my $start = time;
    $one->thread( 'fork', sub { sleep $_[0] }, 7 );
    ok( time - $start > 4, "fork finished" );
    alarm 0
} "fork finished";

done_testing;
