package TEST::Fennec::Handler::TAP;
use strict;
use warnings;

use Fennec;
use Fennec::Util::Alias qw/
    Fennec::Output::Result
    Fennec::Output::Diag
/;

our $CLASS = 'Fennec::Handler';
use_ok $CLASS;

tests 'create' => sub {
    my $one = $CLASS->new( out_std => sub {}, out_err => sub {} );
    isa_ok( $one, $CLASS );
    can_ok( $one, qw/handle fennec_error finish/ );
    lives_ok {
        $one->$_ for qw/finish start bail_out fennec_error/;
    } "stubs";
    throws_ok {
        $one->handle
    } "$CLASS does not implement result()",
      "handle is abstract";
    throws_ok {
        $CLASS->handle
    } "$CLASS does not implement result()",
      "handle is abstract";
};

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
