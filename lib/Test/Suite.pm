package Test::Suite;
use strict;
use warnings;

use Test::Builder;
use Cwd qw/cwd/;
use File::Temp qw/tempfile/;
use Carp;
use Scalar::Util 'blessed';
use Test::Suite::Grouping;
use Test::Suite::TestBase;
use Sub::Uplevel;

our $VERSION = "0.001";
our $SINGLETON;
our $TB = Test::Builder->new;
our @DEFAULT_PLUGINS = qw/Warn Exception More Simple/;

sub import {
    my $class = shift;
    my %options = @_;
    my ( $package, $filename ) = caller();

    if ( my $get_from = $options{ testing }) {
        eval "require $get_from" || croak( $@ );

        my ( $level, $sub, @args ) = $class->_get_import( $get_from, $package );
        next unless $sub;

        push @args => @{ $options{ import_args }} if $options{ import_args };

        $level ? uplevel( $level, $sub, @args )
               : $sub->( @args );
    }

    {
        no strict 'refs';
        push @{ $package . '::ISA' } => 'Test::Suite::TestBase';
    }

    $class->export_plugins( $package, $options{ plugins } );
    Test::Suite::Grouping->export_to( $package );

    my $self = $class->get;
    my $test = $package->new( %options, filename => $filename );
    $self->add_test( $test );
    return $test;
}

sub _get_import {
    my $class = shift;
    my ($get_from, $send_to) = @_;
    my $import = $get_from->can( 'import' );
    return unless $import;

    return ( 1, $import, $get_from )
        unless $get_from->isa( 'Exporter' );

    return ( 1, $import, $get_from )
        if $import != Exporter->can( 'import' );

    return ( 0, $get_from->can('export_to_level'), $get_from, 1, $send_to );
}

sub export_plugins {
    my $class = shift;
    my ( $package, $specs ) = @_;
    my @plugins = @DEFAULT_PLUGINS;

    if ( $specs ) {
        my %remove;
        for ( @$specs ) {
            m/^-(.*)$/ ? ($remove{$1}++)
                       : (push @plugins => $_);
        }

        my %seen;
        @plugins = grep { !($seen{$_}++ || $remove{$_}) } @plugins;
    }

    for my $plugin ( @plugins ) {
        my $name = "Test\::Suite\::Plugin\::$plugin";
        eval "require $name" || die( $@ );
        $name->export_to( $package );
    }
}

sub get { goto &new };

sub new {
    my $class = shift;
    return $SINGLETON if $SINGLETON;

    # Create socket
    my ( $fh, $file ) = tempfile( cwd() . "/.test-suite.$$.XXXX", UNLINK => 1 );
    require IO::Socket::UNIX;
    close( $fh ) || die( $! );
    unlink( $file );
    my $socket = IO::Socket::UNIX->new(
        Listen => 1,
        Local => $file,
    ) || die( $! );

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
    $self->{ tests } ||= {};
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
    my $class = shift;
    my ($result) = @_;
    if (( keys %$result ) == 1 && $result->{ diag }) {
        $TB->diag( $result->{ diag });
        return 1;
    }

    $TB->ok($result->{ result } || 0, $result->{ name });
#    $TB->diag(
#        "  Test failed in file " .
#        ($result->{ filename } || '(NOT FOUND)') .
#        "\n  on line " .
#        ($result->{ line } || '(NOT FOUND)')
#    ) unless $result->{ result };
    $TB->diag( $_ ) for @{ $result->{ debug } || []};
}

sub diag {
    my $self = shift;
    $self->result({ diag => \@_ });
}

sub _send_result {
    croak( "Forking not yet implemented" );
}

sub run {
    my $self = shift;
    croak "Already running"
        if $self->is_running;
    $self->is_running( 1 );
    my $listen = $self->socket;
}

sub DESTROY {
    my $self = shift;
    my $socket = $self->socket;
    close( $socket ) if $socket;
    unlink( $self->socket_file ) if $self->is_parent;
}

1;
