package Fennec::Handler::SubProcess;
use strict;
use warnings;

use base 'Fennec::Handler';

use Fennec::Util::Accessors;
use Fennec::Runner;
use IO::Socket::UNIX;

Accessors qw/socket/;

sub init {
    my $self = shift;
    my $socket = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => Runner->handler->listener->port,
    ) die( $! );
    $self->socket( $socket )->autoflush( 1 );

    print $socket Runner->handler->listener->key . "\n";

    die( "Error connecting to master process $!" )
        unless $self->socket && $self->socket->connected;
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    my $socket = $self->socket;
    print $socket $result->serialize . "\n";
}

sub diag {
    my $self = shift;
    $self->result( Fennec::Result->new(
        diag => [@_],
    ));
}

sub bail_out {
    my $self = shift;
    $self->result( Fennec::Result->new(
        bail_out => $_[0],
    ));
}

sub finish {
    my $self = shift;
    my $socket = $self->socket;
    return unless $socket and $socket->connected;
    $socket->flush;
    close( $socket );
}

sub DESTROY {
    my $self = shift;
    $self->finish;
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
