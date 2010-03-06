package Fennec::Tester::Listener;
use strict;
use warnings;

use IO::Socket::UNIX;
use File::Temp qw/tempfile/;
use Fennec::Tester::Root;
use Fennec::Util qw/add_accessors/;

add_accessors qw/socket file connections/;

sub new {
    my $class = shift;
    my ( $fh, $socket_file ) = tempfile( cwd() . "/.test-suite.$$.XXXX"  );
    close( $fh ) || die( $! );
    unlink( $socket_file );
    my $socket = IO::Socket::UNIX->new(
        Listen => 1,
        Local => $socket_file,
    ) || die( $! );
    return bless({ socket => $socket, file => $file, connections => [] }, $class);
}

sub interation {
    my $self = shift;
}

sub accept_connections {
    # Get new connections
}

sub read {
    # Get results/diag from all connections.
}

sub finish {
    # Loop until all connections are closed.
}

sub DESTROY {
    my $self = shift;
    # Close socket and unlink file.
}

1;
