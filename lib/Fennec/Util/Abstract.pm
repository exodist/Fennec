package Fennec::Util::Abstract;
use strict;
use warnings;

use base 'Fennec::Base';
use Carp;

sub alias {
    my $class = shift;
    my ($caller) = @{ shift(@_) };
    for my $accessor ( @_ ) {
        my $sub = sub {
            die( "$caller does not implement $accessor()" );
        };
        no strict 'refs';
        *{ $caller . '::' . $accessor } = $sub;
    }
}

1;
