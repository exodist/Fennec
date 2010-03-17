package TEST::Fennec;
use strict;
use warnings;

use Fennec groups     => [ 'methods' ],
           generators => [ 'simple' ];

sub test_simple {
    my $self = shift;
    ok( 1, "We got a result" );
    ok( $self->isa( 'TEST::Fennec' ), "Ran as method" );
}

1;
