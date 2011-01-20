package Fennec::Listener;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use POSIX ":sys_wait_h";

accessors qw/read buffer count error_count/;

sub new {
    my $class = shift;
    my ( $read, $write ) = @_;

    my $pid = fork();
    return $pid if $pid;
    $| = 1;

    close( $write );
    bless({ read => $read, buffer => {} }, $class )->run();
}

sub run {
    require Time::HiRes;
    my $alarm = \&Time::HiRes::alarm;
    my $self = shift;
    local $SIG{ALRM} = eval "sub { \$self->flush; \$alarm->( 0.10 )}";
    my $read = $self->read;

    $alarm->(0.10);
    while( my $line = <$read> ) {
        $self->handle_line( $line );
    }

    exit( $self->error_count || 0 );
}

sub handle_line {
    my $self = shift;
    my ( $line ) = @_;
    my ( $pid, $handle, $class, $file, $ln, $msg ) = split( "\0", $line );
    my $id = "$class\0$file\0$ln";
    my $buffer = $self->buffer->{$pid};

    if ( !$buffer || $buffer->{id} ne $id ) {
        $self->render_buffer( $buffer ) if $buffer;
        $buffer = {
            handle => $handle,
            id => $id,
            lines => [],
        };
    }

    push @{ $buffer->{lines} } => $msg;

    $self->buffer->{$pid} = $buffer;
}

sub flush {
    my $self = shift;

}

sub render_buffer {
    my $self = shift;
    my ( $buffer ) = @_;
    if ( $buffer->{handle} eq 'STDERR' && !$ENV{'HARNESS_IS_VERBOSE'} ) {
        print STDERR $_ for @{ $buffer->{ lines }};
    }
    else {
        print STDOUT $_ for @{ $buffer->{ lines }};
    }
}

1;
