package Fennec::Handler::SubProcess;
use strict;
use warnings;

use Fennec::Util qw/add_accessors/;
use base 'Fennec::Handler';

add_accessors qw/socket/;

sub init {
    my $self = shift;
    $self->socket(
        IO::Socket::UNIX->new(
            Peer => Fennec::Runner->get->socket_file,
        )
    );
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

sub finish {
    my $self = shift;
    my $socket = $self->socket;
    return unless $socket and $socket->connected;
    print $socket "shutdown\n";
    close( $socket );
}

sub DESTROY {
    my $self = shift;
    $self->finish;
}

1;
