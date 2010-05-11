package Fennec::Assert::TBCore::Simple;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
require Test::Simple;

our @LIST = qw/ok/;

for my $name ( @LIST ) {
    no strict 'refs';
    next unless Test::Simple->can( $name );
    tester( $name => tb_wrapper( \&{ 'Test::Simple::' . $name }));
}

1;

=head1 NAME

Fennec::Assert::TBCore::Simple - Fennec wrapper for L<Test::Simple>

=head1 DESCRIPTION

Simply wraps L<Test::Simple> so that its functions work better in L<Fennec>.

=head1 WRAPPED FUNCTIONS

=over 4

=item ok()

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
