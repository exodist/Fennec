package Fennec::Consumer::TestBuilder;
use strict;
use warnings;
use Test::Builder;
use Fennec::Interceptor;

use base 'Fennec::Consumer';

sub tb {
    my $self = shift;
    ($self->{ tb }) = @_ if @_;
    return $self->{ tb };
}

sub init {
    my $self = shift;
    $self->tb( Test::Builder->new );
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;
    $self->tb->real_ok($result->result || 0, $result->name);
    $self->tb->real_diag( $_ ) for @{ $result->diag || []};
}

sub diag {
    my $self = shift;
    $self->tb->real_diag( @_ );
}

sub finish {
    my $self = shift;
    $self->tb->done_testing();
}

1;

__END__

=head1 NAME

Fennec::Consumer::TestBuilder - If you really want to output to test builder.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
