package Fennec::Runner;
use strict;
use warnings;
use Carp qw/carp/;
use Scalar::Util qw/blessed/;
use Fennec::Util qw/accessors array_accessors/;
use Fennec::Listener;

accessors qw/pid _write listener/;
array_accessors qw/test_classes/;

my $SINGLETON;

sub init {}

sub import {
    shift->new;
}

sub new {
    return $SINGLETON if $SINGLETON;
    my $class = shift;
    my ( $read, $write );
    pipe( $read, $write );

    my $listener = Fennec::Listener->new( $read, $write );
    close( $read );

    my $old = select( $write );
    $| = 0;
    select( $old );
    $SINGLETON = bless({
        pid      => $$,
        listener => $listener,
        _write   => $write,
    }, $class );
    $SINGLETON->setup_tb;
    $SINGLETON->init( @_ );
    return $SINGLETON;
};

sub ok {
    my $self = shift;

    return $SINGLETON->ok( @_ )
        unless( blessed $self && $self == $SINGLETON );

    require Test::More;
    my ( $status, $name, @diag ) = @_;
    Test::More::ok( $status, $name );
    return $status if $status;
    Test::More::diag( $_ ) for @diag;
    return $status;
}

sub setup_tb {
    my $self = shift;
    my $TB = 0;
    if ( $TB = eval { require Test::Builder; 1 }) {
        Test::Builder->new->use_numbers(0);
        my ( $greator_version ) = ( $Test::Builder::VERSION =~ m/^(\d+)/ );
        if ( $greator_version >= 2) {
        }
        else {
            my $out = $self->_write;
            no warnings 'redefine';
            *Test::Builder::_ending = sub { 1 };
            my $original_print = Test::Builder->can('_print_to_fh');
            *Test::Builder::_print_to_fh = sub {
                my( $tb, $fh, @msgs ) = @_;

                my ( $handle, $output );
                open( $handle, '>', \$output );
                $original_print->( $tb, $handle, @msgs );
                close( $handle );

                my $ohandle = ($fh == $tb->output) ? 'STDOUT' : 'STDERR';

                my @call = $self->get_test_call();
                print $out join( "\0", $$, $ohandle, $call[0], $call[1], $call[2], $_ ) . "\n"
                    for split( /[\n\r]+/, $output );
            };
        }
    }
}

sub get_test_call {
    my $self = shift;
    my $runner;
    my $i = 1;

    while ( my @call = caller( $i++ )) {
        $runner = \@call if !$runner && $call[0]->isa('Fennec::Runner');
        return @call if $call[0]->can('FENNEC');
    }

    return( @$runner );
}

sub load_file {
    my $self = shift;
    my ( $file ) = @_;
    print "Loading: $file\n";
    eval { require $file; 1 } || $self->exception( $file, $@ );
    $self->check_pid();
}

sub check_pid {
    my $self = shift;
    return unless $self->pid != $$;
    die "PID has changed! Did you forget to exit a child process?";
}

sub load_module {
    my $self = shift;
    my $module = shift;
    print "Loading: $module\n";
    eval "require $module" || $self->exception( $module, $@ );
    $self->check_pid();
}

sub run {
    my $self = shift;
    Test::Class->runtests if $INC{'Test/Class.pm'};

    for my $class ( $self->test_classes ) {
        next unless $class && $class->can('TEST_WORKFLOW');
        print "Running: $class\n";
        my $instance = $class->can('new') ? $class->new : bless( {}, $class );
        Test::Workflow::run_tests( $instance );
        $self->check_pid();
    }
}

sub exception {
    my $self = shift;
    my ( $name, $exception ) = @_;
    $self->ok( 0, $name, $exception )
}

sub DESTROY {
    my $self = shift;

    my $out = $self->_write;
    close( $out );

    return unless $$ == $self->pid;

    waitpid( $self->listener, 0 );
    my $exit = $? >> 8;
    exit( $exit );
}

1;
