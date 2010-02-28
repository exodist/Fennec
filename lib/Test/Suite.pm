package Test::Suite;
use strict;
use warnings;

use Test::Builder;
use Cwd qw/cwd/;
use File::Temp qw/tempfile/;
use Carp;
use Scalar::Util 'blessed';
use Test::Suite::Grouping;

our $VERSION = "0.001";
our $SINGLETON;
our $TB = Test::Builder->new;

sub import {
    my $class = shift;
    my %options = @_;
    my ( $package ) = caller();

    {
        no strict 'refs';
        push @{ $package . '::ISA' } => 'Test::Suite::TestBase';
    }

    my $self = $class->get;
    my $test = $package->new(\%options);
    $self->add_test( $test );

    # If there are no options then don't continue.
    return $test unless keys %options;

    my $no_plugin = { map { substr($_, 1) => 1 } grep { m/^-/ } @{ $options{ plugins }}};
    my %seen;
    for my $plugin ( @{ $options{ plugins }}, qw/Warn Exception More Simple/) {
        next if $seen{ $plugin }++;
        next if $no_plugin->{ $plugin };

        my $name = "Test\::Suite\::Plugin\::$plugin";
        eval "require $name" || die( $@ );
        $name->export_to( $package );
    }

    Test::Suite::Grouping->export_to( $package );

    if ( my $tested = $options{ tested }) {
        my @args = $options{ import_args };
        local *{"$package\::_import_args"} = sub { @args };
        my $r = eval "package $package; use $tested _import_args(); 'xxgoodxx'";
        die( $@ ) unless $r eq 'xxgoodxx';
    }
    return $test;
}

sub get { goto &new };

sub new {
    my $class = shift;
    return $SINGLETON if $SINGLETON;

    # Create socket
    (undef, my $file) = tempfile( cwd() . "/.test-suite.$$.XXXX", UNLINK => 1 );
    require IO::Socket::UNIX;
    my $socket = IO::Socket::UNIX->new(
        Listen => 1,
        Local => $file,
    );

    $SINGLETON = bless(
        {
            parent_pid => $$,
            pid => $$,
            socket => $socket,
            socket_file => $file,
        },
        $class
    );
    return $SINGLETON;
}

sub add_test {
    my $self = shift;
    my ( $test ) = @_;
    my $package = blessed( $test );

    croak "$package has already been added as a test"
        if $self->tests->{ $package };

    $self->tests->{ $package } = $test;
}

sub get_test {
    my $self = shift;
    my ( $package ) = @_;
    return $self->tests->{ $package };
}

sub tests {
    my $self = shift;
    return $self->{ tests };
}

sub pid {
    my $self = shift;
    $self->{ pid } = $$ if @_;
    return $self->{ pid };
}

sub parent_pid {
    my $self = shift;
    return $self->{ parent_pid };
}

sub is_parent {
    my $self = shift;
    return ( $$ == $self->parent_pid ) ? 1 : 0;
}

sub socket_file {
    my $self = shift;
    return $self->{ socket_file },
}

sub socket {
    my $self = shift;
    return $self->{ socket } if $$ == $self->parent_pid;

    # If we are in a new child clear existing sockets and make new ones
    unless ( $$ == $self->pid ) {
        delete $self->{ socket };
        delete $self->{ client_socket };
        $self->pid( 1 ); #Set pid.
    }

    $self->{ client_socket } ||= IO::Socket::UNIX->new(
        Peer => $self->socket_file,
    );

    return $self->{ client_socket };
}

sub is_running {
    my $self = shift;
    ($self->{ is_running }) = @_ if @_;
    return $self->{ is_running };
}

sub result {
    my $self = shift;
    croak( "Testing has not been started" )
        unless $self->is_running;

    $self->_handle_result( @_ )
        if ( $self->is_parent );

    $self->_send_result( @_ );
}

sub _handle_result {

}

sub _send_result {

}

sub run {
    my $self = shift;
    croak "Already running"
        if $self->is_running;
    $self->is_running( 1 );
    my $listen = $self->socket;
}

1;
