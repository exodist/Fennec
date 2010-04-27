package Fennec::Collector::Interceptor;
use strict;
use warnings;

use base 'Fennec::Collector';

use Fennec::Util::Accessors;

Accessors qw/intercepted/;

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

=head1 NAME

Fennec::Collector::Interceptor - Intercept output objects instead fo sending
them to parent.

=head1 METHODS

=over 4

=item $results = $obj->intercepted()

Return an array of result objects written.

=item $obj->write( $output )

Write an output object.

=item $obj->init()

Used internally, will destroy any stored output objects if called.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
