package Fennec::Assert::TBCore::More;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::More;

our @LIST = qw/ ok is isnt like unlike cmp_ok can_ok isa_ok new_ok pass fail
                use_ok require_ok is_deeply /;

for my $name ( @LIST ) {
    no strict 'refs';
    next unless Test::More->can( $name );
    tester( $name => tb_wrapper( \&{ 'Test::More::' . $name }));
}

util diag => \&diag;

util note => \&diag;

1;

=head1 NAME

Fennec::Assert::TBCore::More - Fennec wrapper for L<Test::More>

=head1 DESCRIPTION

Simply wraps L<Test::More> so that its functions work better in L<Fennec>.

=head1 WRAPPED FUNCTIONS

=over 4

=item ok()

=item is()

=item isnt()

=item like()

=item unlike()

=item cmp_ok()

=item can_ok()

=item isa_ok()

=item new_ok()

=item pass()

=item fail()

=item use_ok()

=item require_ok()

=item is_deeply()

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
