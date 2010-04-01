package Fennec::Manual::TestSuite;
use strict;
use warnings;

1;

=pod

=head1 NAME

Fennec::Manual::TestSuite - Quick guide to managing a test suite with L<Fennec>

=head1 DESCRIPTION

This guide will get you started writing a L<Fennec> based test suite for your
dist. The first step is to generate the boilerplate t/fennec.t file. I suitable
default can be generated using the fennec_init command within your project
directory.

=head1 GETTIN STARTED

    ~/my/project $ fennec_init

This should have created t/Fennec.t, here is an example:

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Cwd;
    use Fennec::Runner;
    'Fennec::Runner'->init(
        p_files => 2,
        p_tests => 2,
        handlers => [qw/ TAP /],
        random => 1,
        Collector => 'Files',
        ignore => undef,
        filetypes => [qw/ Module /],
        default_asserts => [qw/ Core /],
        $ENV{ FENNEC_FILE } ? ( files => [ cwd() . '/' . $ENV{ FENNEC_FILE }]) : (),
        $ENV{ FENNEC_ITEM } ? ( search => $ENV{ FENNEC_ITEM }) : (),
    );

    Runner->start;

This file serves multiple purposes:

=over 4

=item Configuration file

This is where you configure the Runner than runs all the fennec tests. Other
fennec tools will look for this file and use the configuration it provides.
fennec_prove is one example of a tool that uses this config.

=item Works with prove

You can use prove -I lib t/Fennec.t to run your tests. Module::Build and
Module::Install already know how to run Fennec tests because of this.

=item Parse environment variables

The last 2 items are for environment variables that can be used to tell Fennec
to only run a specified file/test name or line number. This way you do not have
to run the entire test suite every time.

=back

=head1 TEST FILES

L<Fennec> has a plugins system that means test files cna be anything, but the
default is perl modules placed under t/.

Lets say you have a file lib/MyPackage/MyThing.pm. Lets make a Fennec test for
it, you can name the test file anything you want, but the recommended name is
t/MyPackage/MyThing.pm. It is recommended that you mirror the layout of your
lib directory in your tests.

t/MyPackage/MyThing.pm:

    package TEST::MyPackage::MyThing;
    use strict;
    use warnings;

    use Fennec;

    tests 'load MyThing' => sub {
        my $self = shift;
        require_ok MyPackage::MyThing;
    };

    1;

The package can be anything except main, no 2 test files should implement the
same package, and it is recommended that your package be the same as the
package being tested with at least 1 change such as the TEST:: prefix.

You can use the 'tests' keyword to define as many test groups as you want.
Within the test groups you can use all the core asserts by default (see
L<Fennec::Assert::Core>). This list includes all functions normally exported by
L<Test::More>, L<Test::Warn>, and L<Test::Exception>.

=head1 ADVANCED USAGE

=over 4

=item Choosing assert plugins

By default L<Fennec::Assert::Core> is loaded, which in turn loads all Core
assert modules. You can specify alternate ones as well.

This will load L<Fennec::Assert::TBCore> asset libraries instead of Core
libraries. These are wrappers around L<Test::Builder> based test modules.

    use Fennec asserts => [ 'TBCore' ]

You can also directly use assert packages:

    use Fennec asserts => [];
    use Fennec::Assert::Core::More;
    use Fennec::Assert::TBCore::Exception;

=item Choosing workflow plugins

=back

=head1 ADVANCED CONFIGURATION


=head1 SKIP AND TODO

Fennec has the concept of todo tests, tests which are expected to fail. You can
also mark groups as skip if they are really bad.

If an exception is thrown within a TODO block or group then a failing TODO
result will be generated alerting you, however it is todo and will not count as
a failure in the grand scheme.

    #!/usr/bin/perl;
    package TEST::MyTest;
    use strict;
    use warnings;

    # This will run, but failures will not count.
    tests not_yet_implemented => (
        todo => "This will fail",
        method => sub {
            my $self = shift;
            ok( 0, "Hello world" );
        },
    );

    # This will be skipped completely
    tests 'would die' => (
        skip => "This will die",
        method => sub {
            my $self = shift;
            die( "I eat you" );
        },
    );

    # You can also TODO specific asserts.
    tests 'some pass' => sub {
        ok( 1, 'pass' );
        TODO {
            ok( 0, 'fail' );
        } "This will fail, I will fix it later";
    }

    1;

=head1 EARLY VERSION WARNING

L<Fennec> is still under active development, many features are untested or even
unimplemented. Please give it a try and report any bugs or suggestions.

=head1 DOCUMENTATION

=over 4

=item QUICK START

L<Fennec::Manual::Quickstart> - Drop Fennec standalone tests into an existing
suite.

=item FENNEC BASED TEST SUITE

L<Fennec::Manual::TestSuite> - How to create a Fennec based test suite.

=item MISSION

L<Fennec::Manual::Mission> - Why does Fennec exist?

=item MANUAL

L<Fennec::Manual> - Advanced usage and extending Fennec.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
