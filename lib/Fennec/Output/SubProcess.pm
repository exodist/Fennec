sub _send_result {
    # This will be used to serialize and send all results to the main process.
    confess( "Forking not yet implemented" );
}


    $self->{ client_socket } ||= IO::Socket::UNIX->new(
        Peer => $self->_socket_file,
    );


