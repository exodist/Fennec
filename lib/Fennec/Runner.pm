package Fennec::Runner;
use strict;
use warnings;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Fennec::Util qw/accessors array_accessors/;
use Fennec::IO;

accessors qw/pid exit handler/;
array_accessors qw/test_classes/;

my $SINGLETON;

sub init {}

sub import {
    my $class = shift;
    my ( $handler ) = @_;
    $SINGLETON = bless({
        exit => 0,
        handler => $handler || 'Fennec::Handler::TAP'
    }, $class );
    $SINGLETON->hijack_io;
    $SINGLETON->init( @_ );
}

sub new { $SINGLETON };

# Hijak output, including TB so that we can intercept the results.
sub hijack_io {
    my $self = shift;
    my $TB = 0;
    if ( $TB = eval { require Test::Builder; 1 }) {
        Test::Builder->new->use_numbers(0);
        my ( $greator ) = ( $Test::Builder::VERSION =~ m/^(\d+)/ );
        if ( $greator >= 2) {
            my $formatter = Test::Builder2->new->formatter;

            $formatter->use_numbers(0)
                if blessed( $formatter ) =~ m/Test::Builder2::Formatter::TAP/;
        }

        no warnings 'redefine';
        *Test::Builder::_ending = sub { 1 };
    }

    Fennec::IO->init;
    $self->pid( $$ );

    if ( $TB ) {
        no warnings 'redefine';
        *Test::Builder::reset_outputs = sub {
            my $self = shift;
            $self->output        (\*STDOUT);
            $self->failure_output(\*STDERR);
            $self->todo_output   (\*STDOUT);
            return;
        };

        Test::Builder->new->reset_outputs;
    }
}

sub load_file {
    my $self = shift;
    my ( $file ) = @_;
    print "Loading: $file\n";
    eval { require $file; 1 } || $self->exception( $@ );
    $self->check_pid();
}

sub check_pid {
    my $self = shift;
    die "PID has changed! Did you forget to exit a child process?"
        if $self->pid != $$;
}

sub load_module {
    my $self = shift;
    my $module = shift;
    print "Loading: $module\n";
    eval "require $module" || $self->exception( $@ );
    $self->check_pid();
}

sub run {
    my $self = shift;
    Test::Class->runtests if $INC{'Test/Class.pm'};

    for my $class ( $self->test_classes ) {
        next unless $class && $class->can('TEST_WORKFLOW');
        print "Running: $class\n";
        $self->check_pid();
    }

    while ( wait() != -1 ) { sleep 1 }
    exit( $self->exit );
}

sub exception {
    my $self = shift;
    my ( $exception ) = @_;
    print STDERR $exception if $exception;
}

1;
