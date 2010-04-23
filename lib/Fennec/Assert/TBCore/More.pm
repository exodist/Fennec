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
    tester $name => tb_wrapper \&{ 'Test::More::' . $name };
}

util diag => \&diag;

util note => \&diag;

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
