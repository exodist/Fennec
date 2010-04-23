package Fennec::Collector::Interceptor;
use strict;
use warnings;

use base 'Fennec::Collector';

use Fennec::Util::Accessors;

Accessors qw/intercepted/;

sub cull {}

sub init {
    my $self = shift;
    $self->intercepted([]);
}

sub write {
    my $self = shift;
    my ( $output ) = @_;
    push @{ $self->intercepted } => $output;
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
