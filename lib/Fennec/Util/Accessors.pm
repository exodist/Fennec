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

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
