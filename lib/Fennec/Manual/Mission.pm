package Fennec::Manual::Mission;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Fennec::Manual::Mission - A modern testing framework for perl

=head1 WHY WRITE A NEW TEST FRAMEWORK

When it comes to making sure work is tested perl does a pretty good job. The
problem is the with the tools available to achieve this testing. Most test
tools for perl are under the Test:: namespace and rely on L<Test::Builder>.

Fennec is a highly extendable testing framework. Fennec provides all the pieces
necessary to achieve the same functionality of other modern testing frameworks.
Fennec has a further goal of simplifying development of better testing
structures.

Fennec is intended to modernize perl testing, while addressing complaints and
insufficiencies in current perl testing frameworks. Currently the most used and
pervasive perl testing framework is L<Test::Builder> as such most of this
document will make comparisons primarily with that framework.

=head1 LIMITATIONS OF TEST BUILDER

L<Test::Builder> has gotten the job done so far. There is no need to defend
L<Test::Builder>, it's success speeks for itself. Download almost any cpan
module and you will likely see L<Test::Builder> in action. The goal here is not
to bash L<Test::Builder>, but rather to illustrate places where things could be
better.

=over 4

=item Tests are scripts

Tests that rely on L<Test::Builder> tools take on the form of scripts. These
scripts produce TAP output as the only indicator of what is happening. The only
real way to extend L<Test::Builder> is to write libraries of functions that
more or less boil down to an ok( BOOL, NAME ). The only way to intercept
results is using a harness that pareses the TAP output.

=item Results are only in TAP

The only way to find a problem spot is to rely on L<Test::Builder> to
correctly deduce the line number on which the problem occured, or print your
own diagnostics messages. Some more complex functions, such as those in
L<Test::Exception> can throw off L<Test::Builder>'s ability to deduce the line
number of the test that failed. To solve this L<Test::Exception> makes heavy
use of L<Sub::Uplevel> which opens it's own can of worms.

=item Forking is a tricky prospect

Test builder does not play well with fork. If your test forks you cannot use
test functions in both processes. The following example will produce errors in
the harness about tests out of order and duplicate test numbers.

    use Test::Simple;
    use strict;
    use warnings;

    fork();
    ok( 1, "a test" );
    ok( 1, "another test" );
    ok( 1, "and another test" );

=item No randomization of tests

Test builder results are ordered by nature. TAP itself suggests test numbers.
making tests run in random order would involve manually wrapping sets of tests
into subs and creating your own runner to randomize them. Test files are also
run in a consistant order.

=back

=head1 FEATURES OF FENNEC

See L<Fennec::Manual::Features> for the complete list.

=over 4

=item Test files are objects

When you use L<Fennec> the package you are in becomes a L<Fennec::Test> class.
This class is instantiated and all test groups are run as a method on the
object.

=item Results are objects

All results are objects which contain a boolean for pass/fail, but also contain
the group the test was run under, the line number for the test, and much more
context information. See L<Fennec::Result> for more information.

=item Extendability

Fennec has 4 primary places open to extension. Result handlers (to do something
with results other than printing TAP). Test Groups which allow for different
test organization scheme's such as RSPEC. Result generators which fullfill the
same role as Test::XXX has done in the past; that is providing new test utility
functions such as dies_ok. And finally Test::File extensions which can be used
to add new ways of writing tests such as TestML.

See the EXTENDABILITY OF FENNEC section below as well as the documentation for
L<Fennec::Handler>, L<Fennec::Workflow>, L<Fennec::Assert>, and
L<Fennec::File>.

=item Forking just works

All results funnel down to the parent process via a unix socket. The parent
thread then runs each result through each result handler. You can fork and just
expect it to work.

=item Ships with rspec-like testing

Fennec ships with L<Fennec::Workflow::Spec> which is an extension to provide a
variation of spec testing (like Rubies RSPEC). This does nto work exactly the
same as Rubies RSPEC, but it is close. If you want a perfectl clone of RSPEC
you can write it fairly easy using L<Fennec::Workflow> extensions.

=back

=head1 EXTENDABILITY OF FENNEC

Fennec must be extendable above all else. Its one thing to make a test
framework that is modern right now, it is another thing entirely to make a
framework that can remain modern in years to come. Currently there are 4 main
avenues for extending Fennec.

=over 4

=item Asserts

Asserts generate result objects. Assert packages provide test utility
functions. This is similar to most of the modules in the Test::XXX name space.
The difference is that these all produce L<Fennec::Result> objects instead of
issuing results to L<Test::Builder>.

=item Workflows

Test workflows allow for different test organization scheme's such as RSPEC.
You can create workflow objects which are created through utility functions.
These objects are themselves glorified methods that will be run against your
test object. Workflows can be nested and return a list of test sets to be run.
Test sets returned by groups may also contain setup and teardown methods.

=item Result Handlers

When reseults are generated Fennec will forward them to all the initialized
result handlers. Result handlers can do whatever they want with these results.
The default handler is the TAP handler which will output the results in TAP
format to STDOUT.

=item Custom test file types

L<Fennec::File> extensions can be used to add new ways of writing tests
such as writing a TestML extentions.

=back

=head1 THE FUTURE, MAKING FENNEC BETTER

If you have any ideas on improving fennec, improving testing in general, or
even simple complaints about how some testing works, please submit them. If you
need some core changes to be made for an extention or improvement do not
hesitate to ask. Fennec will not fester in its current limitations if it can
avoid it.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
