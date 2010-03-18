package Fennec::Handler::Root::Listener;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Result;
use Fennec::Runner;
use IO::Socket::INET;
use Try::Tiny;
use Carp;

use Cwd qw/cwd/;

our @CHARS = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9, '#', ',', qw{!@$%^&*()_-=+/?.><`~|\\[]\{\}';:"});

Accessors qw/socket port key connections root_handler/;

sub new {
    my $class = shift;
    my ( $root_handler ) = shift;

    my ( $socket, $port );
    do {
        $port = int(rand(90000) + 10000);
        $socket = IO::Socket::INET->new(
            Listen => 1,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Blocking => 0,
        ) || die( $! );
        $socket->blocking( 0 );
    } until( $socket );

    return bless(
        {
            socket => $socket,
            port => $port,
            key => join( map { $CHARS[rand(@CHARS)] } 1 .. 128 ),
            connections => [],
            root_handler => $root_handler,
        },
        $class
    );
}

sub iteration {
    my $self = shift;
    $self->accept_connections;
    $self->read;
}

sub accept_connections {
    my $self = shift;
    # Get new connections
    my $socket = $self->socket;
    while( my $incoming = $socket->accept ) {
        chomp( my $inkey = <$incoming> );
        next unless $inkey;
        next unless $inkey eq $self->key;
        $incoming->blocking( 0 );
        $incoming->autoflush( 1 );
        push @{ $self->connections } => $incoming;
    }
}

sub read {
    my $self = shift;

    my @connections;

    for my $connection (@{ $self->connections }) {
        try { $connection->send( "ping\n" )};
        next unless $connection->connected;

        while ( my $msg = <$connection> ) {
            chomp( $msg );
            $self->process( $msg );
        }

        push @connections => $connection;
    }

    $self->connections( \@connections );
}

sub finish {
    my $self = shift;
    while ( @{ $self->connections }) {
        $self->read;
        sleep 1;
    }
}

sub process {
    my $self = shift;
    my ( $msg ) = @_;
    my $item = Result->deserialize( $msg );
    return Runner->handler->direct_diag( @{ $item->diag })
        if $item->is_diag;
    return Runner->handler->direct_result( $item );
}

sub DESTROY {
    my $self = shift;
    return unless Runner->is_parent;

    # Close sockets and unlink file.
    for my $child ( @{ $self->connections }) {
        try { close( $child )};
    }
    my $socket = $self->socket;
    close( $socket ) if $socket;

    unlink( $self->file );
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
