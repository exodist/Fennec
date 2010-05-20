package Fennec::Assert::TBCore::Differences;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::Differences;

for my $name ( @Test::Differences::EXPORT ) {
    no strict 'refs';
    next unless Test::Differences->can( $name );
    tester( $name => tb_wrapper( \&{ 'Test::Differences::' . $name }));
}

1;

=head1 NAME

Fennec::Assert::TBCore::Differences - Fennec wrapper for L<Test::Differences>

=head1 DESCRIPTION

Simply wraps L<Test::Differences> so that its functions work better in L<Fennec>.

=head1 WRAPPED FUNCTIONS

=over 4

=item eq_or_diff()

=item eq_or_diff_text()

=item eq_or_diff_data()

=item unified_diff()

=item context_diff()

=item oldstyle_diff()

=item table_diff()

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
