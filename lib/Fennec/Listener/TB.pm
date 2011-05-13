package Fennec::Listener::TB;
use strict;
use warnings;

use Fennec::Listener::TB::Handle;

use base 'Fennec::Listener';

use Fennec::Util qw/accessors get_test_call/;
use POSIX ":sys_wait_h";
use Test::Builder;

accessors qw/read write pid reporter_pid/;

sub new {
    my $class = shift;
    my ( $read, $write );
    pipe( $read, $write );

    my $self = bless({
        pid => $$,
        read => $read,
        write => $write,
    }, $class);

    $self->spawn_reporter;
    close( $read );
    $self->read( undef );

    my $old = select( $write );
    $| = 0;
    select( $old );

    $self->setup_tb;

    return $self;
}

sub ok         { shift; Fennec::Util::tb_ok( @_ )        }
sub diag       { shift; Fennec::Util::tb_diag( @_ )      }
sub skip       { shift; Fennec::Util::tb_skip( @_ )      }
sub todo_start { shift; Fennec::Util::tb_todo_start( @_ )}
sub todo_end   { shift; Fennec::Util::tb_todo_end        }

sub setup_tb {
    my $self = shift;
    Test::Builder->new->use_numbers(0);
    my $out = $self->write;

    my $TB = Test::Builder->new;
    $TB->no_ending(1);

    tie( *TBOUT, 'Fennec::Listener::TB::Handle', 'STDOUT', $out );
    tie( *TBERR, 'Fennec::Listener::TB::Handle', 'STDERR', $out );

    my $old = select( TBOUT );
    $| = 1;
    select( TBERR );
    $| = 1;
    select( $old );

    $TB->output(\*TBOUT);
    $TB->todo_output(\*TBOUT);
    $TB->failure_output(\*TBERR);
}

sub spawn_reporter {
    my $self = shift;
    my $pid = fork();

    if ( $pid ) {
        $self->reporter_pid( $pid );
        return $pid;
    }

    my $write = $self->write;
    close( $write );
    $self->write(undef);

    require TAP::Parser;
    accessors qw/buffer count error_count/;

    $self->buffer({});
    $self->count(0);
    $self->error_count(0);
    $self->listen;
}

sub listen {
    my $self = shift;
    require Time::HiRes;
    my $alarm = \&Time::HiRes::alarm;
    my $lock = 0;
    local $SIG{ALRM} = sub {
        $self->flush unless $lock;
        $alarm->( 0.01 )
    };
    my $read = $self->read;

    $alarm->(0.01);
    # Catch odd case were we stop reading too soon
    # TODO: Figure out why it happens.
    for ( 1 .. 2 ) {
        while( my $line = <$read> ) {
            $lock = 1;
            $self->handle_line( $line ) if $line;
            $lock = 0;
        }
        sleep 0.5;
    }

    $alarm->(0);
    $self->flush while keys %{ $self->buffer };

    print STDOUT "1.." . $self->count . "\n";
    exit( $self->error_count || 0 );
}

sub handle_line {
    my $self = shift;
    my ( $line ) = @_;
    my ( $pid, $handle, $class, $file, $ln, $msg ) = split( "\0", $line );

    my $id = "$class $file $ln";
    my $buffer = $self->buffer->{$pid};

    if ( !$buffer || $buffer->{id} ne $id ) {
        $self->render_buffer( $buffer ) if $buffer;
        $buffer = {
            pid   => $pid,
            id    => $id,
            lines => [],
        };
    }

    push @{ $buffer->{lines} } => [ $handle, $msg ];
    $self->buffer->{$pid} = $buffer;
}

sub flush {
    my $self = shift;
    for my $pid ( keys %{ $self->buffer }) {
        my $wait = waitpid( $pid, WNOHANG );
        next unless $wait == -1
                 || $wait == $pid;
        $self->render_buffer(
            delete $self->buffer->{ $pid }
        );
    }
}

sub render_buffer {
    my $self = shift;
    my ( $buffer ) = @_;

    for my $line ( @{ $buffer->{ lines }}) {
        my $parser;
        my $error;

        # Tap::Parser seems to fail randomly?
        for ( 1 .. 3 ) {
            $parser = eval { TAP::Parser->new({ source => $line->[1] })};
            $error = $@;
            last if $parser;

            require Data::Dumper;
            my $debug = Data::Dumper::Dumper({
                error => $error,
                buffer => $buffer,
            });

            warn <<"            EOT"
TAP::Parser encountered a problem... Attempting to recover.

*** This is known to happen from time to time, you can probably ignore this
*** message. This message is here purely to help us debug why this occurs and
*** correct it in a better way in the future.

DEBUG INFO
----------------
$debug
----------------
            EOT
        }

        die "Failed to parse input." unless $parser;

        while ( my $result = $parser->next ) {
            next if $result->is_plan;
            if( $result->is_test ) {
                $self->count( $self->count + 1 );
                $self->error_count( $self->error_count + 1 )
                    if !$result->is_ok;
            }
            if ( $line->[0] eq 'STDERR' && !$ENV{HARNESS_IS_VERBOSE} ) {
                print STDERR $result->raw . "\n";
            }
            else {
                print STDOUT $result->raw . "\n";
            }
        }
    }
}

sub terminate {
    my $self = shift;

    my $write = $self->write;
    close( $write );
    $self->write( undef );

    waitpid( $self->reporter_pid, 0 );
    my $exit = $? >> 8;
    exit( $exit );
}

sub DESTROY {
    my $self = shift;
    my $write = $self->write;
    close( $write ) if $write;
}

1;

__END__

=head1 NAME

Fennec::Listener::TB - Listener used with Test::Builder

=head1 DESCRIPTION

This configured the Test::Builder singleton so that it will work with multiple
processes by sending all results and diag to a central process.

=head1 API STABILITY

Fennec versions below 1.000 were considered experimental, and the API was
subject to change. As of version 1.0 the API is considered stabalized. New
versions may add functionality, but not remove or significantly alter existing
functionality.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
