package Fennec;
use strict;
use warnings;

use Fennec::Util qw/inject_sub/;
use Carp qw/croak/;
our $VERSION = '2.000';

sub defaults {
    (
        utils => [
            qw{
                Test::More Test::Warn Test::Exception Test::Workflow Mock::Quick
                },
        ],
        parallel     => 3,
        runner_class => 'Fennec::Runner',
        with_tests   => [],
    );
}

sub init {
    my $class    = shift;
    my %params   = @_;
    my $importer = $params{caller}->[0];
    my $meta     = $params{meta};

    my $wfmeta = $importer->TEST_WORKFLOW;
    Fennec::Runner->new->collector->update_wfmeta($wfmeta);

    $wfmeta->test_sort( $meta->test_sort )
        if $meta->test_sort;

    no strict 'refs';
    my $stash = \%{"$importer\::"};
    delete $stash->{$_} for qw/ run_tests done_testing/;
}

sub import {
    my $class  = shift;
    my @caller = caller;

    my %defaults = $class->defaults;
    $defaults{runner_class} ||= 'Fennec::Runner';
    my %params = ( %defaults, @_ );
    my $importer = $caller[0];

    eval "require $params{runner_class}; 1" || die $@;
    my $runner_init = $params{runner_class}->is_initialized;
    my $runner      = $params{runner_class}->new;

    die "Fennec cannot be used in package 'main' when the test is used with Fennec::Finder"
        if $runner_init && $caller[0] eq 'main';

    if ( !$runner_init ) {
        require Fennec::EndRunner;
        Fennec::EndRunner->set_runner($runner);
    }

    push @{$runner->loaded_classes} => $importer;

    for my $require ( @{$params{skip_without} || []} ) {
        unless ( eval "require $require; 1" ) {
            $runner->_skip_all(1);
            $runner->collector->skip("'$require' is not installed");
            $runner->collector->finish;
            exit 0;
        }
    }

    require Fennec::Meta;
    my $meta = Fennec::Meta->new(
        %params,
        fennec => $class,
        class  => $importer,
    );

    inject_sub( $importer, 'FENNEC', sub { $meta } );

    my $base = $meta->base;
    if ($base) {
        no strict 'refs';
        eval "require $base" || die $@;
        push @{"$importer\::ISA"} => $base
            unless grep { $_ eq $base } @{"$importer\::ISA"};
    }

    for my $util ( @{$params{utils} || []} ) {
        my $code = "package $importer; require $util; $util\->import(\@{\$params{'$util'}}); 1";
        eval $code || die $@;
    }

    for my $template ( @{$params{with_tests} || []} ) {
        eval "package $importer; with_tests '$template'; 1" || die $@;
    }

    $class->init( %params, caller => \@caller, meta => $meta );

    if ($runner_init) {
        no strict 'refs';
        no warnings 'redefine';
        *{"$importer\::run_tests"} = sub { 1 };
    }
    else {
        my $runner = $params{runner_class}->new;
        no strict 'refs';
        no warnings 'redefine';
        my $has_run = 0;
        *{"$importer\::run_tests"} = sub {
            croak "run_tests() called more than once!"
                if $has_run++;

            Fennec::EndRunner->set_runner(undef);
            $runner->run;
            1;
        };
    }
}

1;

__END__

=pod

=head1 NAME

Fennec - A testers toolbox, and best friend

=head1 DESCRIPTION

Fennec is a testers toolbox, and best friend. Fennec is glue that ties together
several modules and features to make testing easier, and more powerful. Fennec
imports all the common Test::* modules for you, in addition to several other
features.

=head1 SYNOPSYS

There are 2 ways to use Fennec. You can use Fennec directly, or you can use the
shiny sugar-coated interface provided by the add-on module L<Fennec::Declare>.

=head2 DECLARATIVE INTERFACE

B<Note:> In order to use this you B<MUST> install L<Fennec::Declare> which is a
seperate distribution on cpan. This module is seperate because it uses the
controversial L<Devel::Declare> module.

t/some_test.t:
    package TEST::SomeTest;
    use strict;
    use warnings;

    use Fennec::Declare(
        parallel  => 3,
        test_sort => 'random',
    );

    # This is optional, there is a default 'new' if you do not override it.
    sub new { ... }

    # Test blocks are called as methods on an instance of your test package.
    tests group_1 {
        # Note: $self is automatically shifted for you.
        ok( $self, "Got self automatically" );
    };

    test group_2 ( todo => 'This is not ready yet' ) {
        # Note: $self is automatically shifted for you.
        ok( 0, "Not ready" );
    }

    # This has one test that gets run twice, once for each case.
    # The letter is uppercased before each test is run, but restored to
    # lowercase after each test is run.
    describe complex {
        # Note: $self is automatically shifted for you.

        my $letter;
        case a { $letter => 'a' }
        case b { $letter => 'b' }

        before_each uppercase { $letter = uc $letter }
        after_each  restore   { $letter = lc $letter }

        tests is_letter {
            like( $letter, qr/^[A-Z]$/, "Got a letter" );
        }

        # You can nest describe blocks, test blocks inside will inherit cases
        # and before/after blocks from the parent, and can add additional ones.
        describe inner { ... }
    }

    # It is important to always end a Fennec test with this function call.
    run_test();


=head2 PURE INTERFACE

If L<Devel::Declare> and its awesome power of syntax specification scares you,
you can always write your Fennec tests in the stone age like this... just don't
miss any semicolons.

t/some_test.t:
    package TEST::SomeTest;
    use strict;
    use warnings;

    use Fennec(
        parallel  => 3,
        test_sort => 'random',
    );

    # This is optional, there is a default 'new' if you do not override it.
    sub new { ... }

    # Test blocks are called as methods on an instance of your test package.
    tests group_1 => sub {
        my $self = shift;
        ok( 1, "1 is true" );
    };

    test group_2 => (
        todo => 'This is not ready yet',
        code => sub {
            my $self = shift;
            ok( 0, "Not ready" );
        }
    );

    # This has one test that gets run twice, once for each case.
    # The letter is uppercased before each test is run, but restored to
    # lowercase after each test is run.
    describe complex => sub {
        my $self = shift;
        my $letter;
        case a => sub { $letter => 'a' };
        case b => sub { $letter => 'b' };

        before_each uppercase => sub { $letter = uc $letter };
        after_each  restore   => sub { $letter = lc $letter };

        tests is_letter => sub {
            like( $letter, qr/^[A-Z]$/, "Got a letter" );
        };

        # You can nest describe blocks, test blocks inside will inherit cases
        # and before/after blocks from the parent, and can add additional ones.
        describe inner => sub { ... };
    };

    # It is important to always end a Fennec test with this function call.
    run_test();

=head1 FEATURES

=over 4

=item Forking just works

Forking in perl tests that use L<Test::Builder> is perilous at best. Fennec
initiates an L<Fennec::Collector> class which sets up Test::Builder to funnel
all test results to the main thread for rendering. A result of this is that
forking just works.

=item RSPEC support

Those familiar with Ruby may already know about the RSPEC testing process. In
general you C<describe> something that is to be tested, then you define setup
and teardown methods (C<before_all>, C<before_each>, C<after_all>,
C<after_each>) and then finally you test C<it>. See the L</EXAMPLES> section or
L<Test::Workflow> for more details.

=item Concurrency, test blocks can run in parallel

By default all C<test> blocks are run in parallel with a cap of 3 concurrent
processes. The process cap can be set with the C<parallel> import argument.

=item No need to maintain a test count

The test count traditionally was used to ensure your file finished running
instead of exiting silently too early. With L<Test::Builder> and friends this
has largely been replaced with the C<done_testing()> function typically called
at the end of tests. Fennec shares this concept, except you do not call
C<done_testing> yourself, C<run_tests> will do it for you when it finishes.

=item Can be decoupled from Test::Builder

Fennec is built with the assumption that L<Test::Builder> and tools built from
it will be used. However custom L<Fennec::Collector> and L<Fennec::Runner>
classes can replace this assumption with any testing framework you want to use.

=item Can run specific test blocks, excluding others

Have you ever had a huge test that took a long time to run? Have you ever
needed to debug a failing test at the end of the file? How many times did you
need to sit through tests that didn't matter?

With Fennec you can specify the C<FENNEC_TEST> environment variable with either
a line number or test block name. Only tests defined on that line, or with that
name will be run.

=item Predictability: Rand is always seeded with the date

Randomizing the order in which test blocks are run can help find subtle
interaction bugs. At the same time if tests are always in random order you
cannot reliably reproduce a failure.

Fennec always seeds rand with the current date. This means that on any given
date the test run order will always be the same. However different days test
different orders. You can always specify the C<FENNEC_SEED> environment
variable to override the value used to seed rand.

=item Test re-ordering, tests can run in random, sorted, or defined order.

When you load Fennec you can specify a test order. The default is random. You
can also use the order in which they are defined, or sorted (alphabetically)
order. If necessary you can pass in a sorting function that takes a list of all
test-objects as arguments.

=item Diag output is coupled with test output

When you run a Fennec test with a verbose harness (prove -v) the diagnostic
output will be coupled with the TAP output. This is done by sending both output
to STDOUT. In a non-verbose harness the diagnostics will be sent to STDERR per
usual.

=item Reusable test modules

You can write tests in modules using L<Test::Workflow> and then import those
tests into Fennec tests. This is useful if you have tests that you want run in
several, or even all test files.

=item Works with Moose

All your test classes are instantiated objects. You can use Moose to define
these test classes. But you do not have to, you are not forced to use OOP in
your tests.

=back

=head1 DEFAULT IMPORTED MODULES

B<Note:> These can be overriden either on import, or by subclassing Fennec.

=over 4

=item Mock::Quick - Mocking without the eye gouging

L<Mock::Quick> is a mocking library that makes mocking easy. In additon it uses
a declarative style interface. Unlike most other mocking libraries on CPAN, it
does not make people want to gouge their eyes out and curl up in the fetal
position.

=item Test::Workflow - RSPEC for perl.

L<Test::Workflow> is a testing library written specifically for Fennec. This
library provides RSPEC workflow functions and structure. It can be useful on
its own, but combined with Fennec it gets concurrency.

=item Test::More

Tried and True testing module that everyone uses.

=item Test::Warn

L<Test::Warn> - Test code that issues warnings.

=item Test::Exception

L<Test::Exception> - Test code that throws exceptions

=back

=head1 IMPORT ARGUMENTS

=over 4

=item base => 'Some::Base'

Load the specified module and make it the base class for your test class.

=item parallel => $PROC_LIMIT

How many test blocks can be run in parallel. Default is 3. Set to 1 to fork for
each test, but only run one at a time. Set to 0 to prevent forking.

=item runner_class => 'Fennec::Runner'

Specify the runner class. You probably don't need this.

=item skip_without => [ 'Need::This', 'And::This' ]

Tell Fennec to skip the test file if any of the specified modules are missing.

=item test_sort => $SORT

Options: 'random', 'sorted', 'ordered', or a code block.

Code block accepts a list of Test::Workflow::Test objects.

=item utils => [ 'Test::Foo', ... ]

Load these modules instead of the default list.

=item with_tests => [ 'Reusable::Tests', 'Common::Tests' ]

Load these modules that have reusable tests. Reusable tests are tests that are
common to multiple test files.

=back

=head1 EXPORTED FUNCTIONS

=head2 FROM FENNEC

=over 4

=item run_tests()

Should be called at the end of your test file to kick off the RSPEC tests.
Always returns 1, so you can use it as the last statement of your module. You
must only ever call this once per test file.

=back

=head2 FROM Test::Workflow

See L<Test::Workflow> or L</EXAMPLES> for more details.

=over 4

=item with_tests 'Module::Name';

Import tests from a module

=item tests $name => sub { ... };

=item tests $name => ( %params );

=item it $name => sub { ... };

=item it $name => ( %params );

Define a test block

=item describe $name => sub { ... };

Describe a set of tests (group tests and setup/teardown functions)

=item case $name => sub { ... };

Used to run a set of tests against multiple conditions

=item before_all $name => sub { ... };

Setup, run once before any tests in the describe scope run.

=item before_each $name => sub { ... };

Setup, run once per test, just before it runs.

=item around_each $name => sub { ... };

Setup and/or teardown.

=item after_each $name => sub { ... };

Teardown, run once per test, after it finishes.

=item after_all $name => sub { ... };

Teardown, run once, after all tests in the describe scope complete.

=back

=head2 FROM Mock::Quick

See L<Mock::Quick> or L</EXAMPLES> for more details.

=over 4

=item my $control = qclass $CLASS => ( %PARAMS, %OVERRIDES );

=item my $control = qtakeover $CLASS => ( %PARAMS, %OVERRIDES );

=item my $control = qimplement $CLASS => ( %PARAMS, %OVERRIDES );

=item my $control = qcontrol $CLASS => ( %PARAMS, %OVERRIDES );

Used to define, takeover, or override parts of other packages.

=item my $obj = qobj( %PARAMS );

=item my ( $obj, $control ) = qobjc( %PARAMS );

=item my $obj = qstrict( %PARAMS );

=item my ( $obj, $control ) = qstrictc( %PARAMS );

Define an object specification, quickly.

=item my $clear = qclear();

Used to clear a field in a quick object.

=item my $meth = qmeth { ... };

=item my $meth = qmeth( sub { ... } );

Used to define a method for a quick object.

=back

=head2 OTHER

See L<Test::More>, L<Test::Warn>, and L<Test::Exception>

=head1 EXAMPLES

=head1 VIM INTEGRATION

Insert this into your .vimrc file to bind the F8 key to running the test block
directly under your cursor. You can be on any line of the test block (except in
some cases the first or last line.

    function! RunFennecLine()
        let cur_line = line(".")
        exe "!FENNEC_TEST='" . cur_line . "' prove -v -I lib %"
    endfunction

    " Go to command mode, save the file, run the current test
    :map <F8> <ESC>:w<cr>:call RunFennecLine()<cr>
    :imap <F8> <ESC>:w<cr>:call RunFennecLine()<cr>

=head1 RUNNING FENNEC TEST FILES IN PARALLEL

The best option is to use prove with the -j flag.

B<Note: The following is no longer a recommended practice, it is however still
supported>

You can also create a custom runner using a single .t file to run all your
Fennec tests. This has caveats though, such as not knowing which test file had
problems without checking the failure messages.

This will find all *.ft and/or *.pm moduls under the t/ directory. It will load
and run any found. These will be run in parallel

t/runner.t
    #!/usr/bin/perl
    use strict;
    use warnings;

    # Paths are optional, if none are specified it defaults to 't/'
    use Fennec::Finder( 't/' );

    # The next lines are optional, if you have no custom configuration to apply
    # you can jump right to 'run_tests'.

    # Get the runner (singleton)
    my $runner = Fennec::Finder->new;
    $runner->parallel( 3 );

    # You must call this.
    run();

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
