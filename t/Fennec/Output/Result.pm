package TEST::Fennec::Output::Result;
use strict;
use warnings;
use Fennec;

tests load => sub {
    require_ok( 'Fennec::Output::Result' );
};

describe 'workflow a' {
    describe 'workflow b' {
        describe 'workflow c' {
            it 'have_workflow_stack' {
                my $results = capture {
                    ok( 1, "blah" )
                }
                is_deeply(
                    $results->[0]->workflow_stack,
                    [
                        __FILE__,
                        'workflow a',
                        'workflow b',
                        'workflow c',
                    ],
                    "workflow stack is correct"
                );
                is(
                    $results->[0]->testset_name,
                    'have_workflow_stack',
                    "Got testset name"
                );
            }
        }
    }
}

1;
