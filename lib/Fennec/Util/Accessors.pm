package Fennec::Util::Accessors;
use strict;
use warnings;

use base 'Fennec::Base';

sub alias {
    my $class = shift;
    my ($caller) = @{ shift(@_) };
    for my $accessor ( @_ ) {
        my $sub = sub {
            my $self = shift;
            ($self->{ $accessor }) = @_ if @_;
            return $self->{ $accessor };
        };
        no strict 'refs';
        *{ $caller . '::' . $accessor } = $sub;
    }
}

1;
