package Fennec::Consumer::Database;
use strict;
use warnings;

use base 'Fennec::Consumer';

sub init {
    my $self = shift;
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;
}

sub diag {
    my $self = shift;
}

sub finish {
    my $self = shift;
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
