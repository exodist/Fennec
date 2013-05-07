#!/usr/bin/env perl
package Test::Procs;
use strict;
use warnings;

use Fennec parallel => 1;

describe procs_1 => sub {
    my @pids = ($$);

    before_all setup => sub {
        ok( $pids[-1] == $$, "before_all happens in parent" );
        push @pids => $$;
    };

    tests a => sub {
        ok( $$ != $pids[-1], "New proc, even for just 1 test" );
        push @pids => $$;
    };

    after_all teardown => sub {
        ok( $$ == $pids[-1], "Same process as before_all" );
    };
};

describe procs_2 => sub {
    my @pids = ($$);
    my $test_pid;

    before_all setup => sub {
        ok( $pids[-1] == $$, "before_all happens in parent" );
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
    my @caller = caller;
    my @pids   = ($$);
    my $test_pid;

    before_all setup => sub {
        ok( $pids[-1] == $$, "before_all happens in parent" );
        push @pids => $$;
    };

    describe inner => sub {
        before_all inner_setup => sub {
            ok( $pids[-1] == $$, "before_all happens in parent" );
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

        after_all inner_teardown => sub {
            ok( $$ == $pids[-1], "Same process as before_all" );
        };
    };

    after_all teardown => sub {
        ok( $$ == $pids[-1], "Same process as before_all" );
    };
};

1;
