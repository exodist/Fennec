package Fennec::Manual::Specification;
use strict;
use warnings;

1;

=pod

=head1 NAME

Fennec::Manual::Specification - Specification for Fennec

=head1 *** DATED ***

This needs to be updated. Confirm with Exodist when spec and code seem in
conflict.

=head1 DESCRIPTION

Fennec is a test module that addresses several complains I have heard, or
have myself issued forth about perl testing.

=head1 TOOLS

=over 4

=item $ fennec_prove file(s)

=item $ fennec_prove file1 [case(s)] [set(s)] file2 ...

=item $ fennec_prove dir

Command line tool to run specified tests.

=item Fennec::Runner->run( @PARAMS )

Used to run L<Fennec> tests from a test script.

=back

=head1 SYNOPSYS

    package MyModule;
    use strict;
    use warnings;

    package MyModuleTest;
    use strict;
    use warnings;

    # This is also equivilent to 'use MyModule @args;'
    use Fennec testing => 'MyModule', import_args => \@args,
        # Load specified Fennec::XXX plugins, 'more', 'exception', and
        # 'warn' are automatically loaded unless specified with a '-' prefix.
        plugins => [qw//],
        # if 'case' then run all cases in parallel (but sets in sequence)
        # if 'set' then run all cases in sequence, but sets in parallel within them
        parallel => BOOL || 'case' || 'set'
        # Default is true, to randomize order of cases/sets
        random => BOOL,
        # Specify custom set/case default defenition options
        case_defaults => { ... },
        set_defaults => { ... },
    ;

    # Create the optional initialize method that will take care of setup tasks
    # that occur before any case or set is run. Will only be run automatically
    # once.
    sub initialize {
        # Will be a 'MyModuleTest' object with all methods you define in the
        # file, as well as accessors to find current set and case.
        my $self = shift;
    }

    # Define test set 'a', and a method for it to run
    test_set a => (
        # make this whole set todo
        todo => 'reason',
        # skip this whole set
        skip => 'reason',
        # Optional, assert that the set runs specified number of tests
        tests => COUNT,
        # If true than this set will only run in the main process, not a fork.
        # This will prevent it from being run in parallel with others.
        # Default: false
        no_fork => BOOL,
        # force the set to be run in a forked process, useful for tests that
        # might mangle things horribly for other tests.
        force_fork => BOOL,
        # Specify the method to run for this set, defaults to 'set_NAME'
        method => 'name' || \&code,
        # What to do if there is a test failure
        on_fail => OPTION,
            'finish'      # Just keep going if possible, otherwise next set.
            'next_set'    # Move to the next set.
            'next_case'   # Move to the next case.
            'next_module' # Move to the next test module.
            'abort'       # Stop all testing and exit.
    );
    # Define the test code automatically used by set 'a'
    sub set_a {
        # Will be a 'MyModuleTest' object with all methods you define in the
        # file, as well as accessors to find current set and case.
        my $self = shift;
    }

    # Define set 'b', a call to 'test_set' is not necessary if you do not want
    # to set any options.
    sub set_b { ... }

    # If you don't like the magic of finding test subs automatically
    test_set c => sub { ... };

    # the long and ugly version.
    test_set d => (
        ...
        method => sub { ... },
    );

    test_case foo => (
        # Same as test_set() options except no test count.
        # Added:
            # Only run the specified sets
            only_sets => [qw//],
            # Do not run these sets
            skip_sets => [qw//],
    );
    sub case_foo {
        my $self = shift;
        # Setup tasks for this case...
    }

    # Cases have the same defenition styles and options as sets.


=head1 PROBLEMS ADDRESSED

=over 4

=item forking code

This is partially solved by L<Test::More::Fork> as well as L<Test::Fork> and a
few others. But no current solution is ideal.

L<Fennec> will work with forking. When the module if first loaded it will
record the current pid and create a listen socket. If a test is run under
another pid it will connect to the root process's socket and send it the
results as opposed to printing the TAP output itself.

=item perl tests are a collection of scripts

Currently perl tests are usually a collection of scripts under t/ that
hopefully follow a useful or meaningful naming scheme. Scripts start, run their
tests in order, and exit. Running specific groups of tests requires hacking on
the script each time.

=item test randomisation

Cases and sets will be run in random order unless random is turned off when
importing L<Fennec>. Random can also be tunred off using a command line
option. Every set will be run once per case.

=item running only specified tests as well as all

Must be able to run specific cases/sets

    $ fennec_prove TestModule [Case(s)] [Set(s)]

=item test grouping

Tests will be divided into sets. Sets can be run individually as well as in
sequence. Each test will also have an initialization method to do initial
setup. Test classes will also have cases, every set will be run once per case.

=item handle death

Each case and each set within each case will be run using eval or Try::Tiny so
that a single test that blows up will not kill everything. If killing
everything is desired then you can use on_fail => 'abort' in your case/set
defenitions.

If a set or case dies (outside of an eval or dies_ok) it will be considered a
single test failure.

=item tests mirror code

L<Fennec> tests will be modules with a package name nearly identical to
the package being tested.

Options (TIMTOWTDI)

    Module:
    lib/App/MyApp.pm

    Options:
    ts/App/MyApp.pm
    lib/App/TEST/MyApp.pm

Tests can mirror lib inside /ts (/t should be reserved for script based tests
and prove). They can also be in an uppercase 'TEST' directory within the
directory containing the tested module.

You will need to configure L<Module::Build> or L<Module::Install> to ignore
your test files for installation (unless you really don't care, but please do).

L<Module::Build> and L<Module::Install> do not directly support running
L<Fennec> tests, so you can create a test.pl test script that runs the
tests, or a t/suite.t which does the same.

There should probably be extensions to the install/build modules to make
Fennec work.

=item test reporting

When a test fails it should provide the filename, line number, case name and
set name. As well in cases sich as is_deeply it should list all the differences
at the level that breaks (though not all deep differences)

=item most commonly needed test functions

All the functionality of L<Test::Simple>, L<Test::More>, L<Test::Exception>,
and L<Test::Warn> should be exported by default. It is unfortunate, but most
functions will likely need to be re-implemented to work with the forking
capabilities.

=item test output

When fennec tests are run through test.pl or t/fennec.t it should produce
standard TAP output. To deviate from this would be asking for trouble.

=item test output under fennec_prove:

Fennec will maintain a table at the top of the display that will always be
visible. Diagnostics messages will be printed below the table unless quiet is
on. In both quiet and non-quiet mode the final table and all diagnostics
messages will be put into the fennec-out.txt file.

    HH::MM::SS | files | Cases | Sets
    -----------|-------|-------|------
    passes:    | 2     | 15    | 90
    failes:    | 1     | 2     | 2
    skipped:   | 0     | 0     | 1
    todo:      | 0     | 0     | 2
    remaining: | 109   | 12    | 248
    ----------------------------------

    filename | case name | set name | count (tests run so far)
    ---------|-----------|----------|-------
    ..MyFile | ..My Case | ..My Set | 05
    ----------------------------------------

    [messages in verbose mode]

The fennec test runner will exit true in success, false in failure.

=item database

Fennec will record all results into a database. A database tool will be
provided to view information about a test run.

=item coverage

fennec_prove should have a simple flag to turn on coverage testing

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.