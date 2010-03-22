package Fennec::Manual::Mission;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Fennec::Manual::Mission - Why Fennec is here

=head1 WHY WRITE A NEW TEST FRAMEWORK

Perl testing frameworks currently leave a lot to be desired. There are several
projects in the works to try and improve how perl testing is done. These
projects usually focus on solving one or 2 of the problems, sometimes these
solutions are incompatible with eachother, or current testing packages. Fennec
is an attempt to make a testing framework upon which intercompatible solutions
to these problems can be built.

L<Fennec> provides a solid base that is highly extendable. It allows for the
writing of custom nestable workflows (like RSPEC), Custom Asserts (like
L<Test::Exception>), Custom output handlers (Alternatives to TAP), Custom file
types, and custom result passing (collectors). In L<Fennec> all test files are
objects. L<Fennec> also solves the forking problem, thats it, forking just
plain works.

L<Fennec> tries to play nicely with L<Test::Builder>. It will not interfer with
tests that are written using Test::Builder bases tools. There is also a wrapper
that makes it possible to use L<Test::Builder> based asset packages (like
L<Test::Warn>) within Fennec tests.

L<Fennec> core does not attempt to solve all the current problems. However it
does take them all under consideration and tries to provide extendability to
simplify building such solutions. Its not so much Fennec solves your problem as
it is that Fennec lets you solve your problem while allowing you to use
solutions to the other problems at the same time.

=head1 GOALS

=over 4

=item Ease of entry - low learning curve

=item Extendability

=item Compatability

=item Distributability

=back

=head1 PROBLEMS WITH OTHER SOLUTIONS

Some of the big issues being tackled by other projects are as follows.

TODO: Link to projects

=over 4

=item Alternate Workflows

Alternate workflows include RSPEC like testing.

=item Alternate Output

Currently TAP is the standard, and for most cases it is sufficient. The problem
is that most solutions give no thought to those who might want an alternate
format.

=item Assertions

These include L<Test::More> and L<Test::Exception>. Most of these are made
using L<Test::Builder>, and unless your testing solution plays nicely with TB
you will probably have to write your own set of assertions, this can require
re-writing well tested solutions to common problems.

=item Forking

Ability to fork and have both processes generate results. There are 2 current
problems preventing forking tests from working properly. L<Test::Builder>
includes numbers in its TAP output. When you fork you have duplicate numbers,
or out of order numbers. Note - L<Test::Builder2> apparently solves this
problem.

The other problem is much more sinister, and harder to detect. When you fork in
perl all processes have the same STDOUT and STDERR output handles. It is
possible that 2 processes can 'fight' and output results at the same time. When
this happens you can have part of one result, followed by a different result,
before the rest of the first result appears. The more tests you have the more
likely you are to see this. This bug would be completely random and
unpredictable.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
