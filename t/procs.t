#!/usr/bin/env perl
package Test::Procs;
use strict;
use warnings;

use Fennec parallel => 3;

describe procs_1 => sub {
    my @pids = ($$);

    before_all setup => sub {
        ok( $pids[-1] != $$, "In a new process" );
        push @pids => $$;
    };

    tests a => sub {
        ok( $$ == $pids[-1], "Only 1 test, no need for a new process" );
    };

    after_all teardown => sub {
        ok( $$ == $pids[-1], "Same process as before_all" );
    };
};

describe procs_2 => sub {
    my @pids = ($$);
    my $test_pid;

    before_all setup => sub {
        ok( $pids[-1] != $$, "In a new process" );
        push @pids => $$;
    };

    tests a => sub {
        ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
        ok( !$test_pid,      "Did not see other test" );
        $test_pid = $$;
    };

    tests b => sub {
        ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
        ok( !$test_pid,      "Did not see other test" );
        $test_pid = $$;
    };

    after_all teardown => sub {
        ok( $$ == $pids[-1], "Same process as before_all" );
    };
};

describe procs_nested => sub {
    my @pids = ($$);
    my $test_pid;

    before_all setup => sub {
        ok( $pids[-1] != $$, "In a new process" );
        push @pids => $$;
    };

    describe inner => sub {
        before_all setup => sub {
            ok( $pids[-1] != $$, "In a new process" );
            push @pids => $$;
        };

        tests a => sub {
            ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
            ok( !$test_pid,      "Did not see other test" );
            $test_pid = $$;
        };

        tests b => sub {
            ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
            ok( !$test_pid,      "Did not see other test" );
            $test_pid = $$;
        };

        after_all teardown => sub {
            ok( $$ == $pids[-1], "Same process as before_all" );
        };
    };

    after_all teardown => sub {
        ok( $$ == $pids[-1], "Same process as before_all" );
    };
};

1;
