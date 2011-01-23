package Fennec::Runner;
use strict;
use warnings;

BEGIN {
    my $seed = $ENV{'FENNEC_SEED'};
    unless( $seed ) {
        my %date_time;
        @date_time{qw/sec min hour mday mon year/} = localtime(time);
        $date_time{year} += 1900;
        $seed = join("", @date_time{qw/mday mon year/});
    }
    print STDERR "\n*** Seeding random with date ($seed) ***\n",
                 "*** use the 'FENNEC_SEED' environment variable to override ***\n";
    srand( $seed );
}

use Carp qw/carp croak/;
use Scalar::Util qw/blessed/;
use Fennec::Util qw/accessors/;
use Fennec::Listener;

accessors qw/pid listener test_classes/;

my $SINGLETON;

my $listener_class;
sub listener_class {
    unless ( $listener_class ) {
        if (eval { require Test::Builder2; 1 }) {
            require Fennec::Listener::TB2;
            $listener_class = 'Fennec::Listener::TB2';
        }
        elsif ( eval { require Test::Builder }) {
            require Fennec::Listener::TB;
            $listener_class = 'Fennec::Listener::TB';
        }
    }
    return $listener_class;
}

sub init {}

sub import { shift->new() }

sub new {
    my $class = shift;
    return $SINGLETON if $SINGLETON;

    $SINGLETON = bless({
        test_classes => [],
        pid => $$,
        listener => $class->listener_class->new() || croak "Could not init listener!",
    }, $class);

    $SINGLETON->init( @_ );

    return $SINGLETON;
};

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
    die "PID has changed! Did you forget to exit a child process?\n";
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
    Test::Class->runtests if $INC{'Test/Class.pm'} && !$ENV{'FENNEC_TEST'};

    for my $class ( @{ $self->test_classes }) {
        next unless $class && $class->can('TEST_WORKFLOW');
        print "Running: $class\n";
        my $instance = $class->can('new') ? $class->new : bless( {}, $class );
        my $meta = $instance->TEST_WORKFLOW;

        my $prunner;
        if ( my $max = $class->FENNEC->parallel ) {
            require Parallel::Runner;
            $prunner = Parallel::Runner->new( $max );
            $meta->test_run( sub {
                my $sub = shift;
                $prunner->run( sub {
                    $instance->TEST_WORKFLOW->test_run(undef);
                    $sub->();
                });
            });
        }

        Test::Workflow::run_tests( $instance );
        $prunner->finish if $prunner;
        $meta->test_run( undef );
        $self->check_pid();
    }

    $self->listener->terminate();
}

sub exception {
    my $self = shift;
    my ( $name, $exception ) = @_;

    if ( $exception =~ m/^FENNEC_SKIP: (.*)\n/ ) {
        $self->listener->ok( 1, "SKIPPING $name: $1")
    }
    else {
        $self->listener->ok( 0, $name );
        $self->listener->diag( $exception );
    }
}

1;
