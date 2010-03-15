package Fennec::Handler::Root;
use strict;
use warnings;

use base 'Fennec::Handler';

use Fennec::Runner;
use Fennec::Result;
use Fennec::Util::Accessors;
use Fennec::Handler::Root::Listener;
use Carp;

use Scalar::Util qw/blessed/;

Accessors qw/handlers started finished listener failures_list/;

sub new {
    my $class = shift;
    my @handlers;
    for my $handler ( @_ ) {
        my $hpackage = 'Fennec::Handler::' . $handler;
        eval "require $handler" || die( @_ );
        push @handlers => $hpackage->new;
    }

    my $self = bless(
        {
            handlers => $handlers,
            failures_list => [[]],
            listener => Listener->new,
        },
        $class,
    );
}

sub start {
    my $self = shift;
    $handler->start for @{ $self->handlers };
    $self->started( 1 );
}

sub finish {
    my $self = shift;
    $handler->finish for @{ $self->handlers };
    $self->listener->finish;
    $self->finished( 1 );
}

sub push_failures_list {
    my $self = shift;
    push @{ $self->failures_list } => shift( @_ ) if @_;
}

sub pop_failures_list {
    my $self = shift;
    pop @{ $self->failures_list };
}

sub failures {
    my $self = shift;
    if( @_ ) {
        push @$_ => @_
            for @{ $self->failures_list };
    }
    return @{ $self->failures_list->[-1] };
}

sub pre_output {
    my $self = shift;
    $self->_sub_process_refactor;

    croak( "Testing has not been started" )
        unless $self->started;
    croak( "Testing has already finished" )
        if $self->finished;
}

sub result {
    my $self = shift;
    $self->listener->iteration if Runner->is_parent;
    $self->direct_result( @_ );
}

sub diag {
    my $self = shift;
    $self->listener->iteration if Runner->is_parent;
    $self->direct_diag( @_ );
}

sub direct_result {
    my $self = shift;
    my ($result) = @_;
    $self->pre_output;

    croak( "'$result' is not a valid Fennec::Result object" )
        unless $result
           and blessed( $result )
           and $result->isa( Result );

    $_->result( $result ) for @{ $self->handlers };

    # Add failures to the list of failures.
    $self->failures($result) if $result->fail;
}

sub direct_diag {
    my $self = shift;
    my @messages = @_;
    $self->pre_output;

    $_->diag( @messages ) for $self->result_handlers;
}

sub _sub_process_refactor {
    my $self = shift;
    return if $self->is_parent;
    return unless $self->pid_changed;

    $self->pid( $$ );

    require Fennec::Handler::SubProcess;
    $self->handlers([ Fennec::Handler::SubProcess->new(
            $self->listener->file,
    )]);
}

sub _sub_process_exit {
    my $self = shift;
    $self->finish;
    exit;
}

1;
