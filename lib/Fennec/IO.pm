package Fennec::IO;
use strict;
use warnings;
use Fennec::IO::Handle;

use Fcntl;
use POSIX ":sys_wait_h";

my $PPID = $$;
my $FOS = "\0FOS\0\n";
my ( $READ, $WRITE );

sub init {
    init_pipe();
    my $pid = spawn_worker();
    watch( $pid ) if $pid;
}

sub FOS { $FOS }
sub write_handle { $WRITE }

sub init_pipe {
    pipe( $READ, $WRITE ) || die "Could not create pipe: $!";

    my $old = select ( $WRITE );
    $| = 1;
    select( $old );

    my $flags = fcntl($READ, F_GETFL, 0)
        or die "Couldn't get flags for read handle : $!\n";
    $flags = fcntl($READ, F_SETFL, $flags | O_NONBLOCK)
        or die "Couldn't set flags for read handle: $!\n";
}

sub spawn_worker {
    my $pid = fork() || 0;

    unless ( $pid ) {
        # Temporary
        #Inside the worker
        require Fennec::IO::Handle;
        tie( *NEWOUT, 'Fennec::IO::Handle', 'STDOUT' );
        tie( *NEWERR, 'Fennec::IO::Handle', 'STDERR' );
        close( STDOUT ) || die $!;
        close( STDERR ) || die $!;
        *main::STDOUT = *NEWOUT;
        *main::STDERR = *NEWERR;
        select STDOUT;
    }
    autoflush();

    return $pid;
}

sub autoflush {
    my $old = select( STDOUT );
    $| = 1;
    select( STDERR );
    $| = 1;
    select( $old );
}

sub watch {
    my $pid = shift;
    local $SIG{ALRM} = sub { die "alarm" };
    select( $STDOUT );

    require Time::HiRes;
    Time::HiRes->import(qw/sleep/);

    my $handler_class = Fennec::Runner->new->handler;
    eval "require $handler_class; 1" || die $@;
    my $handler = $handler_class->new();

    my $exit;
    while ( 1 ) {
        {
            local $/ = $FOS;
            while ( my $line = <$READ> ) {
                chomp( $line );
                handle_line( $handler, $line );
            }
        }

        my $out = waitpid( $pid, WNOHANG );
        $exit ||= $? > 0 ? $? >> 8 : 0;
        $exit = 0 if $exit && $exit < 0;
        $handler->reap;

        if ($out && $out < 0) {
            $handler->exit( $exit );
            die "Handler failed to exit";
        }
        sleep 0.10;
    }
}

sub handle_line {
    my ( $handler, $line ) = @_;
    my ( $handle, $pid, $package, $ln, $data )
        = ( $line =~ m/^(\w+)\s+(\d+)\s+([\d\w:]+)\s+(\d+)\s*:(.*)$/gs );
    local $/ = "\n";
    return unless $data;

    $handler->handle(
        line => $line,
        handle => $handle,
        pid => $pid,
        data => $data,
        ln => $ln,
        package => $package,
    );
}

1;
