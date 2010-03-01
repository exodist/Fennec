package Test::Suite::Grouping::Set;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Test::Suite::Grouping::Set - A test set

=head1 DESCRIPTION

A test set class.

=head1 EARLY VERSION WARNING

This is VERY early version. Test::Suite does not run yet.

Please go to L<http://github.com/exodist/Test-Suite> to see the latest and
greatest.

=cut

#}}}

use base 'Test::Suite::Grouping::Base';

sub type { 'Set' }

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
