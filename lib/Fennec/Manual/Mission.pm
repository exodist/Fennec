package Fennec::Manual::Mission;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Fennec::Manual::Mission - A modern testing framework for perl

=head1 DESCRIPTION

Fennec is a modern testing framework for perl. When it comes to making sure
work is tested perl does a pretty good job. The problem is the with the tools
available to achieve this testing. Most test tools for perl are under the
Test:: namespace and rely on L<Test::Builder>.

=head1 LIMITATIONS OF TEST BUILDER

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

=back

=head1 FEATURES OF FENNEC

See L<Fennec::Manual::Features> for the complete list.

=over 4

=item Tests are objects

When you use L<Fennec> the package you are in becomes a L<Fennec::Test> class.
This class is instantiated and all test groups are run as a method on the
object.

=item Results are objects

All results are objects which contain a boolean for pass/fail, but also contain
the group the test was run under, the line number for the test, and much more
context information. See L<Fennec::Result> for more information.

=item Extendability

See the EXTENDABILITY OF FENNEC section below.

See Also: L<Fennec::Handler>, L<Fennec::Group>, L<Fennec::Generator>, and
L<Fennec::Test::File>.

=item Forking just works

All results funnel down to the parent process via a unix socket. The parent
thread then runs each result through each result handler. You can fork and just
expect it to work.

=item Ships with rspec-like testing

My take on rspec testing. Not a 100% compatible implementation, but the
extendability of L<Fennec::Group> makes writing a replacement that is 100%
rspec compatible an easily achievable goal.

=back

=head1 EXTENDABILITY OF FENNEC

=over 4

=item Result Generator

=item Test Groups

=item Result Handlers

=item Custom test file types

=back

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 SYNOPSYS

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
