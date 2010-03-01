package Fennec::Grouping::Case;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Fennec::Grouping::Case - Test case class

=head1 DESCRIPTION

A test case.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=cut

#}}}

use base 'Fennec::Grouping::Base';

sub type { 'Case' }

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
