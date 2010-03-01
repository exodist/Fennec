package Test::Suite::Plugin::Warn;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Test::Suite::Plugin::Warn - L<Test::Warn> functionality.

=head1 DESCRIPTION

Wraps the methods from L<Test::Warn> for use in L<Test::Suite>.

=head1 EARLY VERSION WARNING

This is VERY early version. Test::Suite does not run yet.

Please go to L<http://github.com/exodist/Test-Suite> to see the latest and
greatest.

=head1 TESTER FUNCTIONS

See L<Test::Warn> for more details on any of these.

=over 4

=item warning_is()

=item warnings_are()

=item warning_like()

=item warnings_like()

=item warnings_exist()

=cut

#}}}

use Test::Suite::Plugin;
use Test::Suite::TestBuilderImposter;
use Test::Builder;
use Carp;

our @SUBS;
BEGIN {
    @SUBS = qw/warning_is warnings_are warning_like warnings_like warnings_exist/;
}

use Test::Warn @SUBS;

tester $_ => $_ for @SUBS;

1;

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
