package TEST::Main;
use strict;
use warnings;
use Fennec testers => [ 'TestResults' ];

my $thing;

{
    # Capture the list of tests.
    local $fthing = $thing;

    package Test::Main::Example;
    use strict;
    use warnings;
    use Fennec testers => [ 'TestResults' ];

    test_set a_set => sub {

    };

    test_set b_set => sub {

    };

    test_case a_case => sub {

    };

    test_case b_case => sub {

    };

    it highlevel => sub {

    };

    describe top_describe => sub {
        before_all {

        };

        before_each {

        };

        after_each {

        };

        after_all {

        };

        it top_describe_it => sub {

        };

        it_each top_describe_it_each => sub {

        };

        describe sub_describe => sub {
            before_each {

            };

            after_each {

            };

            it sub_describe_it => sub {

            };
        };
    };
}

1;
