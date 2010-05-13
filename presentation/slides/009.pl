
    describe 'Workflow' {
        my $self = shift;

        before_each { $self->do_something }

        it one { ok( 1, "1 is true!" ) }
        it two { ok( 2, "2 is true!" ) }

        after_each { $self->do_something_else }

        # Nested!
        describe more { ... }
    };

    cases {
        my $var;
        case case_a { $var = 1 };
        case case_b { $var = 2 };

        tests tests_a { ok( $var, "var is true" ) };
        tests tests_b { ok( is_prime($var), "var is prime" )};
    }

__END__

Handy workflows to make testing tasks easier

 * These workflows come with Fennec

 * It is also fairly easy to use the Fennec framework to write custom workflows.



