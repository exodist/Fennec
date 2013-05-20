#!/usr/bin/env perl
use strict;
use warnings;

use Fennec;

use_ok 'Data::Dumper';

tests exports => sub {
    my $self = shift;
    can_ok( $self, 'Dumper' );
};

tests dumper => sub {
    my $VAR1;    # Data::Dumper uses this variable

    is_deeply(
        eval Dumper( {a => 1} ),
        {a => 1},
        "Serialize and De-Serialize"
    );
};

done_testing;
