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

use Carp qw/carp croak confess/;
use List::Util qw/shuffle/;
use Scalar::Util qw/blessed/;
use Fennec::Util qw/accessors/;
use Fennec::Collector;
use Parallel::Runner;

accessors qw/pid test_classes loaded_classes parallel collector _ran _skip_all/;

my $SINGLETON;
sub is_initialized { $SINGLETON ? 1 : 0 }

sub init { }

sub import {
    my $self = shift->new();
    $self->_load_guess($_) for @_;
    $self->inject_run( scalar caller );
}

sub inject_run {
    my $self = shift;
    my ( $caller, $sub ) = @_;

    $sub ||= sub { $self->run };

    require Fennec::Util;
    Fennec::Util::inject_sub( $caller, 'run', $sub );
}

sub new {
    my $class = shift;

    croak "listener_class is deprecated, it was thought nobody used it... sorry. See Fennec::Collector now"
        if $class->can('listener_class');

    croak "Runner was already initialized!"
        if $SINGLETON && @_;

    return $SINGLETON if $SINGLETON;

    my %params = @_;

    my $collector =
        $params{collector_class}
        ? Fennec::Collector->new( $params{collector_class} )
        : Fennec::Collector->new();

    $SINGLETON = bless(
        {
            test_classes   => [],
            loaded_classes => [],
            pid            => $$,
            collector      => $collector,
            parallel       => $params{parallel} || 3,
        },
        $class
    );

    $SINGLETON->init(%params);

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
    print "Loading: $file ($$)\n";
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

sub exception {
    my $self = shift;
    my ( $name, $exception ) = @_;

    if ( $exception =~ m/^FENNEC_SKIP: (.*)\n/ ) {
        $self->collector->ok( 1, "SKIPPING $name: $1" );
        $self->_skip_all(1);
    }
    else {
        $self->collector->ok( 0, $name );
        $self->collector->diag($exception);
    }
}

sub run {
    my $self = shift;

    $self->_ran(1);

    my @to_run;

    for my $class ( @{$self->loaded_classes} ) {
        next unless $class && $class->can('TEST_WORKFLOW');
        push @to_run => $self->to_run_loaded($class);
    }

    for my $class ( @{$self->test_classes} ) {
        push @to_run => $self->to_run_load($class);
    }

    my $pfiles = $self->prunner( $self->parallel );
    my $force_fork = $self->parallel ? 1 : 0;

    for my $file ( shuffle @to_run ) {
        $pfiles->run( $file, $force_fork );
    }

    $pfiles->finish();
    $self->collector->collect;
    $self->collector->finish();
}

sub _to_run {
    my $self = shift;
    my ($class) = @_;

    return sub {
        my $instance = $class->can('new') ? $class->new : bless( {}, $class );
        my $ptests   = Parallel::Runner->new( $class->FENNEC->parallel );
        my $pforce   = $class->FENNEC->parallel ? 1 : 0;
        my $meta     = $instance->TEST_WORKFLOW;

        $meta->test_wait( sub { $ptests->finish } );
        $meta->test_run(
            sub {
                $ptests->run( $_[0], $pforce );
            }
        );

        Test::Workflow::run_tests($instance);
        $ptests->finish;
        $self->check_pid;
    };
}

sub to_run_loaded {
    my $self = shift;
    my ($class) = @_;

    return unless $class && $class->can('TEST_WORKFLOW');

    my $inner = $self->_to_run($class);
    return sub {
        local $self->{pid} = $$;
        print "# Running: $class ($$)\n";
        $inner->();
    };
}

sub to_run_load {
    my $self = shift;
    my ($item) = @_;

    return sub {
        local $self->{pid} = $$;

        my %loaded = map { $_ => 1 } @{$self->loaded_classes};
        $self->_load_guess($item);
        my @new = grep { !$loaded{$_} } @{$self->loaded_classes};

        for my $class (@new) {
            my $inner = $self->_to_run($class);

            next unless $class && $class->can('TEST_WORKFLOW');
            print "# Running: $class ($$)\n";
            $inner->();
        }
    };
}

sub prunner {
    my $self = shift;
    my ($max) = @_;

    $self->{prunner} ||= do {
        my $runner = Parallel::Runner->new($max);

        $runner->reap_callback(
            sub {
                my ( $status, $pid, $pid_again, $proc ) = @_;

                # Status as returned from system, so 0 is good, 1+ is bad.
                $self->exception( "Child process did not exit cleanly", "Status: $status" )
                    if $status;
            }
        );

        $runner->iteration_callback( sub { $self->collector->collect } );

        $runner;
    };

    return $self->{prunner};
}

sub DESTROY {
    my $self = shift;
    return if $self->_ran || $self->_skip_all;

    my $tests = join "\n" => map { "#   * $_" } @{$self->loaded_classes};

    print STDERR <<"    EOT";

# *****************************************************************************
# ERROR: run_tests() was never called!
#
# This usually means you ran a Fennec test file directly with prove or perl,
# but the file does not call run_tests at the end.
#
# This is new behavior as of Fennec 2.000. Old versions used a couple of evil
# hacks to make it work without calling run_tests. These resulted in things
# such as broken coverage tests, broken Win32 (who cares right?), and other
# strange and hard to debug behavior.
#
# Fennec Tests loaded, but not run:
$tests
#
# *****************************************************************************

    EOT
    exit(1);
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

=head1 CUSTOM RUNNER CLASS

If you use a test framework that is not based on L<Test::Builder> it may be
useful to subclass the runner and override the collector_class() and init()
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
