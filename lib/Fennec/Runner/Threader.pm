package Fennec::Runner::Threader;
use strict;
use warnings;
use Fennec::Util qw/add_accessors/;
use POSIX ();
use Time::HiRes;
use base 'Exporter';

add_accessors qw/pid max_files max_partitions max_cases max_sets files partitions cases sets/;

sub new {
    my $class = shift;
    my %proto = @_;
    $proto{ pid } = $$;

    return bless(
        {
            files => [],
            partitions => [],
            cases => [],
            sets => [],
            %proto,
        },
        $class
    );
}

sub thread {
    my $self = shift;
    my ( $type, $code, @args ) = @_;
    $type .= 's';
    my $msub = "max_$type";
    my $max = $self->$msub || 1 unless $type eq 'forks';
    return $self->_fork( $type, $max, $code, \@args ) if $type eq 'forks' || $max > 1;
    return $code->( @args );
}

sub _fork {
    my $self = shift;
    my ( $type, $max, $code, $args ) = @_;

    # This will block if necessary
    my $tid = $self->get_tid( $type, $max )
        unless $type eq 'forks';

    my $pid = fork();
    if ( $pid ) {
        return $self->tid_pid( $type, $tid, $pid )
            unless ( $type eq 'forks' );

        until ( waitpid( $pid, &POSIX::WNOHANG )) {
            Fennec::Runner->get->listener->iteration;
            sleep(0.10);
        }
        return;
    }

    # Make sure this new process does not wait on the previous process's children.
    $self->{$_} = [] for qw/files partitions cases sets/;

    $code->( @$args );
    $self->cleanup;
    Fennec::Runner->get->_sub_process_exit;
}

sub get_tid {
    my $self = shift;
    my ( $type, $max ) = @_;
    my $existing = $self->$type;
    while ( 1 ) {
        for my $i ( 1 .. $max ) {
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
    my ( $type, $tid, $pid ) = @_;
    $self->$type->[$tid] = $pid if $pid;
    return $self->$type->[$tid];
}

sub pids {
    my $self = shift;
    return grep { $_ } map {(@{ $self->$_ })} qw/files partitions cases sets/;
}

sub cleanup {
    my $self = shift;
    for my $pid ( $self->pids ) {
        waitpid( $pid, 0 );
    }
}

sub DESTROY {
    my $self = shift;
    return $self->cleanup;
}

1;
