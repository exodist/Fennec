package Fennec;
use strict;
use warnings;

use Fennec::Util qw/inject_sub/;

our $VERSION = '0.100';

sub defaults {(
    utils => [qw/
        Test::More Test::Warn Test::Exception Test::Workflow
    /],
    utils_with_args => {
    },
    parallel => 3,
    runner_class => 'Fennec::Runner',
    with_tests => [],
)}

sub init {
    my $class = shift;
    my %params = @_;
    my $importer = $params{caller}->[0];
    my $meta = $params{meta};

    my $wfmeta = $importer->TEST_WORKFLOW;
    $wfmeta->ok( sub { Fennec::Runner->new->listener->ok( @_ )});
    $wfmeta->diag( sub { Fennec::Runner->new->listener->diag( @_ )});
    $wfmeta->test_sort( $meta->test_sort )
        if $meta->test_sort;

    no strict 'refs';
    my $stash = \%{"$importer\::"};
    delete $stash->{$_} for qw/ run_tests done_testing/;
}

sub import {
    my $class = shift;
    my @caller = caller;
    my %defaults = $class->defaults;
    $defaults{runner_class} ||= 'Fennec::Runner';
    my %params = ( %defaults, @_ );
    my $importer = $caller[0];

    $class->_restart_with_runner( $defaults{runner_class}, \@caller );

    Fennec::Runner->new->test_classes_push( $importer );

    for my $require ( @{$params{skip_without} || []}) {
        die "FENNEC_SKIP: '$require' is not installed\n"
            unless eval "require $require; 1";
    }

    require Fennec::Meta;
    my $meta = Fennec::Meta->new(
        fennec => $class,
        class => $importer,
        %params,
    );

    inject_sub( $importer, 'FENNEC', sub { $meta });

    my $base = $meta->base;
    if ( $base ) {
        no strict 'refs';
        eval "require $base" || die $@;
        push @{ "$importer\::ISA" } => $base
            unless grep { $_ eq $base } @{ "$importer\::ISA" };
    }

    for my $util ( @{ $meta->utils }) {
        my $code = "package $importer; require $util; $util\->import(\@{\$params{'$util'}}); 1";
        eval $code || die $@;
    }

    for my $template ( @{ $meta->with_tests }) {
        eval "package $importer; with_tests '$template'; 1" || die $@;
    }

    $class->init( %params, caller => \@caller, meta => $meta );
}

sub _restart_with_runner {
    my $class = shift;
    my ( $runner_class, $caller ) = @_;
    # If the Fennec test file was run directly we need to re-run perl and run the
    # test file through Fennec::Runner. The alternative is an END block.
    if ( $0 eq $caller->[1] ) {
        $ENV{PERL5LIB} = join( ':', @INC );
        exec "$^X -M$runner_class -e '" . <<"        EOT";
            our \$runner;
            BEGIN {
                \$runner = Fennec::Runner->new;
                \$runner->load_file(\"$0\")
            }
            \$runner->run();'
        EOT
    }
}

1;

__END__

=pod

=head1 NAME

Fennec - A test helper providing RSPEC, Workflows, Parallelization, and Encapsulation.

=head1 DESCRIPTION

Fennec started as a project to improve the state of testing in Perl. Fennec
looks to existing solutions for most problems, so long as the existing
solutions help meet the features listed below.

=head1 FEATURES

=over 4

=item Forking Works

Forking in tests just plain works. You can fork, and run assertions (tests) in
both processes.

=item Test groups can be run alone

Encapsulated test groups can be run individually, without running the entire
file. (See L<Test::Workflow>)

=item Parallelization within test files

Encapsulated test groups can be run in parallel if desired. (On by default with
up to 3 processes)

=item Test reordering

Tests groups can be sorted, randomized, or sorted via a custom method. (This
comes see L<Test::Workflow>)

=item Test::Builder and Test::Builder2 compatibility

Fennec is compatible with L<Test::Builder> based tools. The goal is to have
support for L<Test::Builder2> as soon as it is released, maybe shortly before.

=item Ability to decouple from Test::Builder

Fennec is configurable to work on alternatives to L<Test::Builder>.

=item No need to formally end tests

You do not need to put anything such as done_testing() at the end of your test file.

=item Test counting is handled for you

You do not need to worry about test counts.

=item Diagnostic messages are grouped with the failed test

Annoyed when your test failue and the diagnostics messages about that test are
decoupled?

    ok 1 - foo
    ok 2 - bar
    not ok 3 - baz
    ok 4 - bannana
    ok 5 - pear
    # Test failure on line 67
    # expected: 'baz'
    #      got: 'bazz'

This happens because normal output is sent to STDOUT, while errors are sent to
STDERR. This is important in a non-verbose harness so that you can still see
error messages. In a verbose harness however it is just plain annoying. Fennec
checks the verbosity of the harness, and sends diagnostic messages to STDOUT
when the harness is verbose.

B<Note:> This is not IO redirection or handle manipulation, your warnings and
errors will still go to STDERR.

=back

=head1 SYNOPSIS

    package MyTest;
    use strict;
    use warnings;
    use Fennec;

    tests foo => sub {
        ok( 1, 'bar' );
    };

    tests another => sub {
        ok( 1, 'something passed' );
    };

    1;

By default these test groups will be run in parallel. They will also be run in
random order by default. See the L</CONFIGURATION> for more details on
controling behavior. Also see L<Test::Workflow> for more useful and poweful
test groups and structures.

=head2 FRIENDLIER INTERFACE

B<If you use L<Fennec::Declare> you can write tests like this:>

    package MyTest;
    use strict;
    use warnings;
    use Fennec;

    tests foo {
        ok( 1, 'bar' );
    }

    1;

Thats right, no C<=E<gt> sub> and no trailing ';'.

=head1 RUNNING ONLY A SPECIFIC GROUP

     1: package MyTest;
     2: use strict;
     3: use warnings;
     4: use Fennec;
     5:
     6: tests foo => sub {
     7:     ok( 1, 'bar' );
     8: };
     9:
    10: tests another => sub {
    11:    ok( 1, 'something passed' );
    12: };
    13:
    14: 1;

In the above code there are 2 test groups, 'foo', and 'another'. If you wanted,
you could run just one, without the others running. Fennec looks at the
'FENNEC_TEST' environment variable. If the variable is set to a string, then
only the test groups with that string as a name will run.

    $ FENNEC_TEST="foo" prove -Ilib -v t/FennecTest.t

In addition, you could provide a line number, and only the test group defined
across that line will be run. For example, to run 'foo' you could give the line
number 6, 7 or 8 to run that group alone.

    $ FENNEC_TEST="7" prove -Ilib -v t/FennecTest.t

This will run only test 'foo'. The use of line numbers makes editor integration
very easy. Most editors will let you bind a key to running the above command
replacing t/FennecTest.t with the current file, and automatically inserting the
current line into FENNEC_TEST.

=head1 EDITOR INTEGRATION

=head2 VI/VIM

Insert this into your .vimrc file to bind the F8 key to running the current
test in the current file:

    function! RunFennecLine()
        let cur_line = line(".")
        exe "!FENNEC_TEST='" . cur_line . "' prove -v -I lib %"
    endfunction

    " Go to command mode, save the file, run the current test
    :imap <F8> <ESC>:w<cr>:call RunFennecLine()<cr>

=head1 MODULES LOADED AUTOMATICALLY WITH FENNEC

=over 4

=item Test::More

The standard perl test library. L<Test::More>

=item Test::Exception

One of the more useful test libraries, used to test code that throws exceptions
(dies). L<Test::Exception>

=item Test::Warn

Test code that issues warnings. L<Test::Warn>

=item Test::Workflow

Provides RSPEC, and several other workflow related helpers. Also provides the
test group encapsulation. L<Test::Workflow>

=item Mock::Quick

Quick and effective mocking with no action at a distance side effects.
L<Mock::Quick>

=back

=head1 MODULES FENNEC MAKES AN EFFORT TO SUPPORT

=over 4

=item Test::Class

A Fennec class can also be a Test::Class class.

=item Test::Builder

If Fennec did not support this who would use it?

=item Test::Builder2

Test::Builder2 is not out yet, and some specific functionality necessary for
Fennec has yet to be fully implemented. Fennec will develop support fot TB2 as
it matures. The goal is to have a version of Fennec that works with TB2 as soon
as TB2 is released, if not before.

=back

=head1 CONFIGURATION

There are 2 ways to configure Fennec. One is to specify configuration options
at import. The other is to subclass Fennec and override the defaults() method.

Configuration options:

=over 4

=item utils => [ qw/ModuleA ModuleB .../ ]

Provide a list of modules to load. They will be imported as if you typed
C<use MODULE>.

=item utils_with_args => { ModuleName => [ ...ARGS... ]}

This is the same as utils except you can specify arguments to pass into
ModuleName->import().

=item parallel => $MAX

Specify the maximum number of processes Fennec should use to run your tests.
Set to 0 to never create a new process. Depedning on conditions 1 MAY fork for
test groups while still only running 1 at a time, but this behavior is not
guarenteed.

Default: 3

=item runner_class => $CLASS

Specify the runner class. Default: L<Fennec::Runner>

=item test_sort => $SORT

This sets the test sorting method for Test::Workflow test groups.  Accepts
'random', 'sort', a codeblock, or 'ordered'. This uses a fuzzy matching, you
can use the shorter versions 'rand', and 'ord'.

Defaults to: 'rand'

=over 4

=item 'random'

Will shuffle the order. Keep in mind Fennec sets the random seed using the date
so that tests will be determinate on the day you write them, but random
over time.

=item 'sort'

Sort the test groups by name. When multiple tests are wrapped in before_all or
after_all the describe/cases block name will be used.

=item 'ordered'

Use the order in which the test groups were defined.

=item sub { my @tests = @_; ...; return @new_tests }

Specify a custom method of sorting. This is not the typical sort {} block, $a
and $b will not be set.

=back

=head2 AT IMPORT

    use Fennec parallel => 5,
                  utils => [ 'My::Util' ],
                  ... Other Options ...;

=head2 BY SUBCLASS

    package My::Fennec;
    use base 'Fennec';

    sub defaults {(
        utils => [qw/
            Test::More Test::Warn Test::Exception Test::Workflow
        /],
        utils_with_args => {
            My::Util => [qw/function_x function_y/],
        },
        parallel => 5,
        runner_class => 'Fennec::Runner',
    )}

    # Hook, called after import
    sub init {
        my $class = shift;
        # All parameters passed to import(), as well as caller => [...] and meta => $meta
        my %params = @_;

        ...
    }

    1;

=head1 MORE COMPLETE EXAMPLE

This is a more complete example than that which is given in the synopsis. Most
of this actually comes from L<Method::Workflow>, See those docs for more
details. Significant sections are in seperate headers, but all examples should
be considered part of the same long test file.

B<NOTE:> All blocks, including setup/teardown are methods, you can shift @_ to
get $self.

=head2 BASIC EXAMPLES

    package MyTest;
    use strict;
    use warnings;
    use Fennec;

    # Tests can be at the package level
    use_ok( 'MyClass' );

    # Fennec works with Test::Class
    use base 'Test::Class';

    sub tc_test : Test(1) {
        my $self = shift;
        ok( 1, 'This is a Test::Class test' );
    }

    tests loner => sub {
        my $self = shift;
        ok( 1, "1 is the loneliest number... " );
    };

=head2 RSPEC WORKFLOW

Here setup/teardown methods are declared in the order in which they are run,
but they can really be declared anywhere within the describe block and the
behavior will be identical.

    describe example => sub {
        my $self = shift;
        my $number = 0;
        my $letter = 'A';

        before_all setup => sub { $number = 1 };

        before_each letter_up => sub { $letter++ };

        # it() is an alias for tests()
        it check => sub {
            my $self = shift;
            is( $letter, 'B', "Letter was incremented" );
            is( $number, 2,   "number was incremented" );
        };

        after_each reset => sub { $number = 1 };

        after_all teardown => sub {
            is( $number, 1, "number is back to 1" );
        };

        describe nested => sub {
            # This nested describe block will inherit before_each and
            # after_each from the parent block.
            ...
        };
    };

=head3 FENNEC'S RSPEC IMPROVEMENT

Fennec add's to the RSPEC toolset with the around keyword.

    describe addon => sub {
        my $self = shift;

        around_each localize_env => sub {
            my $self = shift;
            my ( $inner ) = @_;

            local %ENV = ( %ENV, foo => 'bar' );

            $inner->();
        };

        tests foo => sub {
            is( $ENV{foo}, 'bar', "in the localized environment" );
        };
    };

=head2 CASE WORKFLOW

Cases are used when you have a test that you wish to run under several r tests
conditions. The following is a trivial example. Each test will be run once
under each case. B<Beware!> this will run (cases x tests), with many tests and
cases this can be a huge set of actual tests. In this example 8 in total will
be run.

B<Note:> The 'cases' keyword is an alias to describe. case blocks can go into
any workflow and will work as expected.

    cases check_several_numbers => sub {
        my $number;
        case one => sub { $number = 2 };
        case one => sub { $number = 4 };
        case one => sub { $number = 6 };
        case one => sub { $number = 8 };

        tests is_even => sub {
            ok( !$number % 2, "number is even" );
        };

        tests only_digits => sub {
            like( $number, qr/^\d+$/i, "number is all digits" );
        };
    };

    1;

=head1 ADDITIONAL USER DOCUMENTATION

=over 4

=item L<Fennec::Recipe::SingleRunner>

=item L<Fennec::Recipe::CustomFennec>

=item L<Fennec::Recipe::CustomRunner>

=back

=head1 SEE ALSO

=over 4

=item L<Test::Workflow>

=item L<Fennec::Runner>

=item L<Mock::Quick>

=item L<Test::More>

=item L<Test::Exception>

=item L<Test::Warn>

=item L<Test::Class>

=item L<Test::Builder>

=back

=head1 NOTES

When you C<use Fennec>, it will check to see if you called the file directly.
If you directly called the file Fennec will restart Perl and run your test
through L<Fennec::Runner>.

=head1 CAVEATS

When running a test group by line, Fennec takes it's best guess at which group
the line number represents. There are 2 ways to get the line number of a
codeblock:

The first is to use the L<B> module. The L<B> module will return the
line of the first statement within the codeblock.

The other is to define the codeblock in a function call, such as
C<tests foo =E<gt> sub {...}>, tests() can then use caller() which will return
the last line of the statement.

Combining these methods, we can get the approximate starting and ending lines
for codeblocks defined through Fennec's keywords.

This will break if you do something like:

    tests foo => \&my_test;
    sub my_test { ... }

But might work just fine if you do:

    tests foo => \&my_test;
    sub my_test { ... }

But might run both tests in this case when asking to run 'baz' by line number:

    tests foo => \&my_test;
    tests baz => sub {... }
    sub my_test { ... }

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
