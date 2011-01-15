package Fennec::Runner;
use strict;
use warnings;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Fennec::IO;

my $PID;

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
        $self->failure_output(\*STDOUT);
        $self->todo_output   (\*STDOUT);
        return;
    };

    Test::Builder->new->reset_outputs;
}

our @TEST_CLASSES;

sub run_file {
    my $file = shift;
    print "Loading: $file\n";
    eval { require $file } || die $@;
    run();
}

sub run_module {
    my $module = shift;
    print "Loading: $module\n";
    eval "require $module" || die $@;
    run();
}

sub run {
    while( my $class = shift( @TEST_CLASSES )) {
        print "Running: $class\n";
    }

    die "PID has changed! Did you forget to exit a child process?"
        if $PID != $$;

    while ( wait() != -1 ) { sleep 1 }
}

sub push_test_class {
    shift;
    push @TEST_CLASSES => @_;
}

1;
