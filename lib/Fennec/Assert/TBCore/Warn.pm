package Fennec::Assert::TBCore::Warn;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::Warn;

our @LIST = qw/warning_is warnings_are warning_like warnings_like warnings_exist/;

for my $name ( @LIST ) {
    no strict 'refs';
    next unless Test::Warn->can( $name );
    tester $name => tb_wrapper \&{ 'Test::Warn::' . $name };
}

1;

=head1 NAME

Fennec::Assert::TBCore::Warn - Fennec wrapper for L<Test::Warn>

=head1 DESCRIPTION

Simply wraps L<Test::Warn> so that its functions work better in L<Fennec>.

=head1 WRAPPED FUNCTIONS

=over 4

=item warning_is()

=item warnings_are()

=item warning_like()

=item warnings_like()

=item warnings_exist()

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
