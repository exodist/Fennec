package Fennec::Assert::TBCore::Exception;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::Exception;

our @LIST = qw/ throws_ok dies_ok lives_ok lives_and /;

for my $name ( @LIST ) {
    no strict 'refs';
    next unless Test::Exception->can( $name );
    tester $name => tb_wrapper \&{ 'Test::Exception::' . $name };
}

1;

=head1 NAME

Fennec::Assert::TBCore::Exception - Fennec wrapper for L<Test::Exception>

=head1 DESCRIPTION

Simply wraps L<Test::Exception> so that its functions work better in L<Fennec>.

=head1 WRAPPED FUNCTIONS

=over 4

=item throws_ok()

=item dies_ok()

=item lives_ok()

=item lives_and()

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
