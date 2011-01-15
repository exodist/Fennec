package Fennec::Runner;
use strict;
use warnings;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Fennec::IO;

my $EXIT = 0;
my $PID;
our @TEST_CLASSES;

# Hijak output, including TB so that we can intercept the results.
BEGIN {
    require Test::Builder;
    Test::Builder->new->use_numbers(0);
    my ( $greator ) = ( $Test::Builder::VERSION =~ m/^(\d+)/ );
    if ( $greator >= 2) {
        my $formatter = Test::Builder2->new->formatter;

        $formatter->use_numbers(0)
            if blessed( $formatter ) =~ m/Test::Builder2::Formatter::TAP/;
    }

    no warnings 'redefine';
    *Test::Builder::_ending = sub { 1 };

    Fennec::IO->init;
    $PID = $$;

    *Test::Builder::reset_outputs = sub {
        my $self = shift;
        $self->output        (\*STDOUT);
        $self->failure_output(\*STDERR);
        $self->todo_output   (\*STDOUT);
        return;
    };

    Test::Builder->new->reset_outputs;
}

sub load_file {
    my $file = shift;
    print "Loading: $file\n";
    eval { require $file } || exception( $@ );
    check_pid();
}

sub check_pid {
    die "PID has changed! Did you forget to exit a child process?"
        if $PID != $$;
}

sub load_module {
    my $module = shift;
    print "Loading: $module\n";
    eval "require $module" || exception( $@ );
    check_pid();
}

sub run {
    Test::Class->runtests if $INC{'Test/Class.pm'};
    for my $class ( @TEST_CLASSES ) {
        next unless $class && $class->can('TEST_WORKFLOW');
        print "Running: $class\n";
        check_pid();
    }

    while ( wait() != -1 ) { sleep 1 }
    exit( $EXIT );
}

sub push_test_class {
    shift;
    push @TEST_CLASSES => @_;
}

sub exception {

}

1;
