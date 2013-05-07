package Fennec::Runner;
use strict;
use warnings;

BEGIN {
    my @ltime = localtime;
    $ltime[5] += 1900;
    for ( 3, 4 ) {
        $ltime[4] = "0$ltime[$_]" unless $ltime[$_] > 9;
    }
    my $seed = $ENV{FENNEC_SEED} || join( '', @ltime[5, 4, 3] );
    print "\n*** Seeding random with date ($seed) ***\n";
    srand($seed);
}

use Carp qw/carp croak/;
use Scalar::Util qw/blessed/;
use Fennec::Util qw/accessors/;
use Fennec::Listener;

accessors qw/pid listener test_classes/;

my $SINGLETON;

my $listener_class;

sub listener_class {
    unless ($listener_class) {
        if ( $^O eq 'MSWin32' ) {
            require Fennec::Listener::TBWin32;
            $listener_class = 'Fennec::Listener::TBWin32';
        }
        elsif ( eval { require Test::Builder2; 1 } ) {
            require Fennec::Listener::TB2;
            $listener_class = 'Fennec::Listener::TB2';
        }
        else {
            require Fennec::Listener::TB;
            $listener_class = 'Fennec::Listener::TB';
        }
    }
    return $listener_class;
}

sub init { }

sub import {
    my $self = shift->new();
    return unless @_;

    $self->_load_guess($_) for @_;
    $self->inject_run( scalar caller );
}

sub inject_run {
    my $self = shift;
    my ($caller) = @_;

    require Fennec::Util;
    Fennec::Util::inject_sub(
        $caller,
        'run',
        sub { $self->run }
    );
}

sub new {
    my $class = shift;
    return $SINGLETON if $SINGLETON;

    $SINGLETON = bless(
        {
            test_classes => [],
            pid          => $$,
            listener     => $class->listener_class->new() || croak "Could not init listener!",
        },
        $class
    );

    $SINGLETON->init(@_);

    return $SINGLETON;
}

sub _load_guess {
    my $self = shift;
    my ($item) = @_;

    if ( ref $item && ref $item eq 'CODE' ) {
        $self->_load_guess($_) for ( $self->$item );
        return;
    }

    return $self->load_file($item)
        if $item =~ m/\.(pm|t|pl)$/i
        || $item =~ m{/};

    return $self->load_module($item)
        if $item =~ m/::/
        || $item =~ m/^\w[\w\d_]+$/;

    die "Not sure how to load '$item'\n";
}

sub load_file {
    my $self = shift;
    my ($file) = @_;
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
    my $self   = shift;
    my $module = shift;
    print "Loading: $module\n";
    eval "require $module" || $self->exception( $module, $@ );
    $self->check_pid();
}

sub run {
    my $self = shift;
    Test::Class->runtests if $INC{'Test/Class.pm'} && !$ENV{'FENNEC_TEST'};

    for my $class ( @{$self->test_classes} ) {
        next unless $class && $class->can('TEST_WORKFLOW');
        print "Running: $class\n";
        my $instance = $class->can('new') ? $class->new : bless( {}, $class );
        my $meta = $instance->TEST_WORKFLOW;
        $meta->debug_long_running( $instance->FENNEC->debug_long_running );

        my $prunner;
        if ( my $max = $class->FENNEC->parallel ) {
            if ( $^O eq 'MSWin32' ) {
                print "Parallization unavailable on windows.\n";
            }
            else {
                $prunner = $self->get_prunner( max => $max );

                $meta->test_wait( sub { $prunner->finish } );
                $meta->test_run(
                    sub {
                        my ( $sub, $test, $obj ) = shift;
                        $prunner->run(
                            sub {
                                my ($parent) = @_;
                                $self->listener->setup_child( $parent->write_handle ) if $parent;
                                $sub->();
                            },
                            1,
                        );
                    }
                );
            }
        }

        Test::Workflow::run_tests($instance);
        $prunner->finish if $prunner;
        $meta->test_run(undef);
        $self->check_pid();
    }

    $self->listener->terminate();
}

sub get_prunner {
    my $self   = shift;
    my %params = @_;

    require Parallel::Runner;
    my $prunner = Parallel::Runner->new( $params{max}, pipe => 1 );

    $prunner->reap_callback(
        sub {
            my ( $status, $pid, $pid_again, $proc ) = @_;

            while ( my $data = eval { $proc->read() } ) {
                $self->listener->process($data);
            }

            # Status as returned from system, so 0 is good, 1+ is bad.
            $self->exception( "Child process did not exit cleanly", "Status: $status" )
                if $status;
        }
    );

    $prunner->iteration_callback(
        sub {
            my $runner = shift;
            for my $proc ( $runner->children ) {
                while ( my $data = eval { $proc->read() } ) {
                    $self->listener->process($data);
                }
            }
        }
    );

    return $prunner;
}

sub exception {
    my $self = shift;
    my ( $name, $exception ) = @_;

    if ( $exception =~ m/^FENNEC_SKIP: (.*)\n/ ) {
        $self->listener->ok( 1, "SKIPPING $name: $1" );
    }
    else {
        $self->listener->ok( 0, $name );
        $self->listener->diag($exception);
    }
}

1;

__END__

=head1 NAME

Fennec::Runner - The runner class that loads test files/classes and runs them.

=head1 DESCRIPTION

Loads test classes and files, processes them, then runs the tests. This class
is a singleton instantiated by import() or new(), whichever comes first.

=head1 USING THE RUNNER

If you directly run a file that has C<use Fennec> it will re-execute perl and
call the test file from within the runner. In most cases you will not need to
use the runner directly. However you may want to create a runner script or
module that loads multiple test files at once before running the test groups.
This section tells you how to do that.

The simplest way to load modules and files is to simply use Fennec::Runner with
filenames and/or module names as arguments.

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Fennec::Runner qw{
        Some::Test::Module
        a_test_file.t
        /path/to/file.pl
        Other::Module
    };

    run();

This will attempt to guess weather each item is a module or a file, then
attempt to load it. Once all the files are loaded, C<run()> will be
exported into your namespace for you to call.

You can also provide coderefs to generate lists of modules and files:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Fennec::Runner sub {
        my $runner = shift;
        ...
        return ( 'Some::Module', 'a_file.pl' );
    };
    run();

If you want to have more control over what is loaded, and do not want C<run()>
to be run until you run it yourself you can do this:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Fennec::Runner;

    our $runner = Fennec::Runner->new(); # Get the singleton
    $runner->load_file( 'some_file.t' );
    $runner->load_module( 'Some::Module' );
    ...
    $runner->run();

For regular Fennec tests this works perfectly fine. However if any of the test
files use L<Test::Class> you will have to wrap the load method calls in a BEGIN
block.

=head1 CUSTOM RUNNER CLASS

If you use a test framework that is not based on L<Test::Builder> it may be
useful to subclass the runner and override the listener_class() and init()
methods.

For more information see L<Fennec::Recipe::CustomRunner>.

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
