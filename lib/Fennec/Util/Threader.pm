package Fennec::Util::Threader;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Runner;
use POSIX ();
use Time::HiRes;

Accessors qw/max pids/;

sub new {
    my $class = shift;
    my ($max) = @_;
    return bless(
        { pids => [], pid => $$, max => $max || 1 },
        $class
    );
}

sub thread {
    my $self = shift;
    my ( $code, $force_fork ) = @_;
    $force_fork = 0 if $self->max > 1;

    return $self->_fork( $code, $force_fork )
        if $force_fork || $self->max > 1;

    return $code->();
}

sub _fork {
    my $self = shift;
    my ( $code, $forced ) = @_;

    # This will block if necessary
    my $tid = $self->get_tid
        unless $forced;

    my $pid = fork();
    if ( $pid ) {
        return $self->tid_pid( $tid, $pid )
            unless $forced;

        until ( waitpid( $pid, &POSIX::WNOHANG )) {
            Runner->handler->listener->iteration;
            sleep(0.10);
        }
        return;
    }

    # Make sure this new process does not wait on the previous process's children.
    $self->{pids} = [];

    $code->();
    $self->cleanup;
    Runner->_sub_process_exit;
}

sub get_tid {
    my $self = shift;
    my $existing = $self->pids;
    while ( 1 ) {
        for my $i ( 1 .. $self->max ) {
            if ( my $pid = $existing->[$i] ) {
                my $out = waitpid( $pid, &POSIX::WNOHANG );
                $existing->[$i] = undef
                    if ( $pid == $out || $out < 0 );
            }
            return $i unless $existing->[$i];
        }
        sleep 1;
    }
}

# Get or set the pid for a tid.
sub tid_pid {
    my $self = shift;
    my ( $tid, $pid ) = @_;
    $self->pids->[$tid] = $pid if $pid;
    return $self->pids->[$tid];
}

sub cleanup {
    my $self = shift;
    for my $pid ( $self->pids ) {
        next unless $pid;
        waitpid( $pid, 0 );
    }
}

sub DESTROY {
    my $self = shift;
    return $self->cleanup;
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
