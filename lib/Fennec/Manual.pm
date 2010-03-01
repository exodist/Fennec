package Fennec::Manual;
use strict;
use warnings;

1;


__END__

=pod

=head1 NAME

Fennec::Manual - A more modern testing framework for perl

=head1 DESCRIPTION

Fennec is a test framework that addresses several complains I have heard,
or have myself issued forth about perl testing. It is still based off
L<Test::Builder> and uses a lot of existing test tools.

Please see L<Fennec::Specification> for more details.

=head1 WHY FENNEC

Fennec is intended to do for perl testing what L<Moose> does for OOP. It makes
all tests classes, and defining test cases and test sets within that class is
simple. In traditional perl testing you would have to manually loop if you
wanted to runa set of tests multiple times in different cases, it is difficult
to make forking tests, and you have limited options for more advanced test
frameworks.

Fennec runs around taking care of the details for you. You simply need to
specify your sets, your cases, and weither or not you want the sets and cases
to fork, run in parrallel or in sequence. Test sets and cases are run in random
order by default. Forking should just plain work without worrying about the
details.

The Fennec fox is a hyper creature, it does a lot of running around, because of
this the name fits. As well Fennec is similar in idea to Moose, so why not name
it after another animal? Finally I already owned the namespace for a dead
project, and the namespace I wanted was taken.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 SYNOPSYS

Lets assume you have a module My::Module, to write a test object for it you can
create lib/My/TEST/Module.pm or ts/My/Module.pm. If in the ts/ directory you
should prefix the package name with TEST::

    package TEST::My::Module;

Both package names are listed:

    package My::TEST::Module;
    use strict;
    use warnings;

    use Fennec testing => 'My::Module',
                    random => 1; #Randomize tests (on by default)

    our $GLOBAL;

    # You can also call it initialize if you prefer long names.
    # This will only be run once, prior to the first test case.
    sub init {
        my $self = shift;
        $self->do_stuff;
    }

    # Define a test case
    test_case ALL_PASS => sub {
        my $self = shift;
        $GLOBAL = 1;
    };

    # Define another test case just as a sub.
    sub case_MORE_PASS {
        my $self = shift;
        $GLOBAL = 1;
    }

    test_case advanced => (
        method => \&_do_advanced,
        todo => "These will all fail because GLOBAL is 0",
        ...
    );

    sub _do_advanced { $GLOBAL = 0 }

    # Define a test set, this will be run once per case
    test_set SET_A => sub {
        my $self = shift;
        ok( $GLOBAL, "Testing GLOBAL" );
        is( $GLOBAL, 1, "Testing GLOBAL again" );
    };

    # Define another set
    set_SET_B => sub {
        my $self = shift;
        ok( $GLOBAL > 0, "Global is positive" );
        ok( $GLOBAL != 0, "Global is not zero" );
    };

    test_set advanced => (
        method => sub { $GLOBAL = 0 },
        todo => 'global is 0, these fail.',
        ...
    );

    1;

=head1 TOOLS

=over 4

=item $ prove_fennec

Command line to to run the test suite.

*** This utility is not yet complete ***

=back

=head1 PLUGINS

Plugins are used to provide new functionality for the test writer. For instance
all the functionality of L<Test::More>, L<Test::Exception::LessClever>,
L<Test::Warn> and L<Test::Simple> are provided by plugins. If you want to add
new tester or utility functions for use in test modules you may do so in a
plugin.

To create a plugin create a module directly under the L<Fennec::Plugin>
namespace. Define testers and utilies.

    package Fennec::Plugin::MyPlugin;
    use strict;
    use references;
    use Fennec::Plugin;

    # define a util function
    util my_diag => sub { Fennec->diag( @_ ) };

    # define a tester
    tester my_ok => (
        min_args => 1,
        max_args => 2,
        code => sub {
            my ( $result, $name ) = @_;
            return ( $result ? 1 : 0, $name );
        },
    );

    # Define one with a prototype
    tester my_dies_ok => sub(&;$) {
        eval $_[0]->() || return ( 1, $_[1]);
        Fennec->diag( "Test did not die as expected" );
        return ( 0, $_[1] );
    };

    1;

Look at L<Fennec::TestHelper> and L<Fennec::Plugin> for information
on testing plugins.

=head1 WRAPPER PLUGINS

Plugins can be made to wrap around existing L<Test::Builder> based testing
utilities. This is how L<Test::More> and L<Test::Warn> functionality is
provided. Here is the Test::More wrapper plugin as an example.

    package Fennec::Plugin::More;
    use strict;
    use warnings;

    use Fennec::Plugin;

    our @SUBS;
    BEGIN {
        @SUBS = qw/ is isnt like unlike cmp_ok is_deeply can_ok isa_ok /;
    }

    use Test::More import => \@SUBS;

    tester $_ => $_ for @SUBS;
    util diag => sub { Fennec->diag( @_ ) };
    util todo => sub(&$) {
        my ( $code, $todo ) = @_;
        local $Fennec::Plugin::TODO = $todo;
        $code->();
    };

    1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
