#!/usr/bin/env perl
use strict;
use warnings;

use Fennec::Declare;

use_ok 'Data::Dumper';

tests exports {
    # Note: $self is shifted for you, and is an instance of your test package.
    can_ok( $self, 'Dumper' );
}

tests dumper {
    my $VAR1;    # Data::Dumper uses this variable

    is_deeply(
        eval Dumper( {a => 1} ),
        {a => 1},
        "Serialize and De-Serialize"
    );
}

done_testing;
