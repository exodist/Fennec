package Fennec::Runner;
use strict;
use warnings;

use Fennec::Interceptor;
use Fennec::Files;
use Fennec::Result;
use Fennec::Runner::Stack;
use Fennec::Runner::Root;
use Fennec::Runner::Threader;
use Fennec::Runner::Args qw/parse_args/;
use Fennec::Util qw/add_accessors/;
use Scalar::Util qw/blessed/;
use Carp         qw/croak confess/;

our $SINGLETON;

add_accessors qw/no_load ignore inline run_only stack test random files
                 _is_subprocess socket_file test_threader file_threader
                 is_running/;

sub import {
    my $class = shift;
    my $caller = caller;
    my $sub = sub {
        return $SINGLETON if $SINGLETON;
        croak( 'Fennec::Runner has not yet been initialized' );
    };
    no strict 'refs';
    *{ $caller . '::Runner' } = $sub;
}

sub get { goto &new };

sub new {
    my $class = shift;
    my %proto = @_;

    unless( $SINGLETON ) {
        unless ( $proto{ files }) {
            my $plugins = delete $proto{ file_plugins } || [ 'Module' ];
            for my $plugin ( @$plugins ) {
                $plugin = 'Fennec::File' . $plugin;
                local $@;
                eval "require $plugin"
                    || croak "Could not load file plugin $plugin: $@";
                push @files => $plugin->find;
            }
        }

        if ( my $args = $proto{ argv } ) {
            %proto = ( %proto, parse_args(@$args));
        }

        my $self = bless(
            {
                parent_pid => $$,
                pid => $$,
                tests => {},
                failures => [],
                random => 1,
                ignore => [],
                file_threader => Fennec::Runner::Threader->new(
                    max => $proto{ p_files }
                ),
                test_threader => Fennec::Runner::Threader->new(
                    max => $proto{ p_tests }
                ),
                %proto,
            },
            $class
        );
        $SINGLETON = $self;

        $self->_init_output;
    }

    return $SINGLETON;
}


#{{{ Test related methods
sub add_test {
    my $self = shift;
    my ( $test ) = @_;
    my $package = blessed( $test );

    croak "$package has already been added as a test"
        if $self->tests->{ $package };

    $self->tests->{ $package } = $test;
}

sub get_test {
    my $self = shift;
    my ( $package ) = @_;
    return unless $package;
    return $self->tests->{ $package };
}

sub tests {
    my $self = shift;
    return $self->{ tests };
}
#}}}


sub result_handlers {
    my $self = shift;
    push @{ $self->{ result_handlers }} => @_ if @_;
    return @{ $self->{ result_handlers }};
}

sub listener {
    my $self = shift;
    return unless $self->is_parent;

    unless ( $self->{ listener }) {
        require Fennec::Runner::Listener;
        my $listener = Fennec::Runner::Listener->new;
        $self->socket_file( $listener->file );
        $self->{ listener } = $listener;
    }

    return $self->{ listener };
}

sub run {
    my $self = shift;
    croak "Already running"
        if $self->is_running;
    croak "run() may only be run from the parent process."
        unless $self->is_parent;

    $self->stack = Fennec::Runner::Stack->new();
    $self->is_running( 1 );

    croak("No listener")
        unless $self->listener;
    croak("No listener_file")
           unless $self->listener->file;
    croak("No listener socket")
           unless $self->listener->socket;

    for my $file ( @{ $self->files }) {
        $self->file_threader->thread(
            sub { $file->load; $self->stack->run },
            'force_fork',
        );
    }

    $self->listener->finish if $self->is_parent;
    $_->finish for $self->result_handlers;

    exit if $self->is_subprocess;
    return 0 if (@{ $self->files->bad_files });
    return !$self->failures;
}

sub _init_output {
    my $self = shift;
    my $plugins = delete $self->{ output } || [ 'TAP', 'Database' ];
    $plugins = [ $plugins ] unless ref $plugins eq 'ARRAY';
    my @loaded;
    for my $plugin ( @$plugins ) {
        my $pclass = 'Fennec::Handler::' . $plugin;
        eval "require $pclass" || die( $@ );
        push @loaded => $pclass->new;
    }
    $self->{ result_handlers } = \@loaded;
}

1;

__END__

=pod

=head1 NAME

Fennec::Runner - The core of Fennec

=head1 DESCRIPTION

This is the class that kicks off the testing.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 CONSTRUCTOR OPTIONS

    my $tester = Fennec::Runner->new( option => 'value' );

=over 4

=item no_load => BOOL

Do not load the test files.

=item ignore => [ qr{}, qr{}, ... ]

When searching for files skip any that match any of these expressions.

=item case => NAME

Only run the specified case in each test file.

=item set => NAME

Only runt he specified set in each case.

=back

=head1 CLASS METHODS

=over 4

=item $singleton = $class->new( %params )

Create a new instance. See the CONSTRUCTOR OPTIONS section above for more
details. Fennec::Runner is a singleton, that means that the first call will
create the object, but all future calls will ignore any parameters and return
the first object created.

=item $singleton = $class->get()

Alias to new which makes more sense for a singleton.

=back

=head1 ACCESSORS

These are simple read/write accessors except where otherwise noted. Most of
these are accessors to construction parameters. Many will have no effect when
changed.

=over 4

=item $obj->no_load()

Simple accessor to construction arg.

=item $obj->ignore()

Simple accessor to construction arg.

=item $obj->case()

Simple accessor to construction arg.

=item $obj->set()

Simple accessor to construction arg.

=item @failures = $obj->failures( @add_failures )

Add or retrieve failures. Failures should be L<Fennec::Result> objects.

=back

=head1 OBJECT METHODS

These are methods that are mroe than simple accessors.

=over 4

=item $list = $obj->files()

Return an arrayref of all files specified at construction, loaded from config,
or found by a search of the project directory.

=item $obj->add_test( $test )

Add a <Fennec::Test> object to be tested when run is called.

=item $test = $obj->get_test( $package )

Get the singleton test for the specified package.

=item $tests = $obj->tests

Get the hashref storing all the package => $test relationships.

=item $pid = $obj->pid()

Returns the current process id as provided by $$.

=item $pid = $obj->parent_pid()

Returns the pid of the process which instantiated the Fennec singleton.

=item $bool = $obj->is_parent()

Returns true if the current process is the process in which the singleton was
instantiated.

=item $bool = $obj->is_running()

Check if the tests are currently running.

=item $obj->result({ result => $BOOL, name => 'My Test', ... })

Issue a test result for output. You almost certainly do not want to call this
directly. If you are witing a plugin please see L<Fennec::Tester> or the
PLUGINS section of L<Fennec::Manual>.

=item $obj->diag( "message 1", "message 2", ... )

An interface to Test::Builder->diag() (which has been overriden). You can use
this to report diagnostics information.

=item $obj->run()

Run the tests. Will die if they are already running, or if the process is ntot
he parent.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
