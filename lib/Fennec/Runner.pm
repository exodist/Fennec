package Fennec::Runner;
use strict;
use warnings;

use Fennec::Interceptor;
use Fennec::Files;
use Fennec::Result;
use Fennec::Runner::Root;
use Fennec::Runner::Threader;
use Fennec::Util qw/add_accessors/;
use Scalar::Util qw/blessed/;
use List::Util   qw/shuffle/;
use Carp         qw/croak confess/;

our $SINGLETON;

add_accessors qw/no_load ignore inline case set test random files
                 _is_subprocess socket_file threader is_running/;

sub get { goto &new };

sub new {
    my $class = shift;
    my %proto = @_;

    unless( $SINGLETON ) {

        my $file_types = delete $proto{ file_types };
        $file_types = [ $file_types ? $file_types : () ] unless ref $file_types eq 'ARRAY';

        my $self = bless(
            {
                parent_pid => $$,
                pid => $$,
                tests => {},
                failures => [],
                random => 1,
                ignore => [],
                %proto,
                files => Fennec::Files->new( @$file_types ),
                threader => Fennec::Runner::Threader->new,
            },
            $class
        );
        $SINGLETON = $self;

        $self->_init_output;
    }

    return $SINGLETON;
}

#{{{ Result related methods
sub failures {
    my $self = shift;
    push @{ $self->{ failures }} => @_ if @_;
    return @{ $self->{ failures }};
}

sub result {
    my $self = shift;
    $self->direct_result( @_ );
    $self->listener->iteration if $self->is_parent;
}

sub diag {
    my $self = shift;
    confess 'this is an object method, not a class method'
        unless blessed( $self );
    $self->direct_diag( @_ );
    $self->listener->iteration if $self->is_parent;
}

sub direct_result {
    my $self = shift;
    my ($result) = @_;
    $self->_sub_process_refactor;

    croak( "Testing has not been started" )
        unless $self->is_running;

    croak( "result() takes a Fennec::Result object" )
        unless $result
           and blessed( $result )
           and $result->isa( 'Fennec::Result' );

    $_->result( $result ) for $self->result_handlers;

    # Add failures to the list of failures.
    $self->failures($result) unless $result->result;
}

sub direct_diag {
    my $self = shift;
    confess 'this is an object method, not a class method'
        unless blessed( $self );
    my @messages = @_;
    $self->_sub_process_refactor;

    $_->diag( @messages ) for $self->result_handlers;
}
#}}}

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
    return $self->tests->{ $package };
}

sub tests {
    my $self = shift;
    return $self->{ tests };
}
#}}}

#{{{ Process related methods
sub pid_changed {
    my $self = shift;
    my $pid = $$;
    return 0 if $self->pid == $pid;
    return $pid;
}

sub pid {
    my $self = shift;
    return $self->{ pid };
}

sub parent_pid {
    my $self = shift;
    return $self->{ parent_pid };
}

sub is_parent {
    my $self = shift;
    confess 'this is an object method, not a class method'
        unless blessed( $self );
    return if $self->pid_changed;
    return ( $self->pid == $self->parent_pid ) ? 1 : 0;
}

sub is_subprocess {
    my $self = shift;
    return !$self->is_parent;
}

sub _sub_process_refactor {
    my $self = shift;
    confess 'this is an object method, not a class method'
        unless blessed( $self );
    return if $self->is_parent;
    return unless $self->pid_changed;

    $self->{ pid } = $$;

    require Fennec::Handler::SubProcess;
    $self->{ result_handlers } = [ Fennec::Handler::SubProcess->new ];
}

sub _sub_process_exit {
    my $self = shift;
    $_->finish for $self->result_handlers;
    exit;
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

    $self->is_running( 1 );

    $self->files->load;
    $self->_run_tests;
    $self->listener->finish if $self->is_parent;
    $_->finish for $self->result_handlers;

    exit if $self->is_subprocess;
    return 0 if (@{ $self->files->bad_files });
    return !$self->failures;
}

sub _run_tests {
    my $self = shift;
    $self->_sub_process_refactor;
    my @tests = values %{ $self->tests };
    @tests = shuffle @tests if $self->random;

    for my $test ( @tests ) {
        $self->test( $test );
        $self->diag( "Running test class " . ref($test) );
        $self->threader->thread( 'file', sub { $test->run( $self->case, $self->set )});
        $self->test( undef );
        $self->listener->iteration if $self->is_parent;
    }
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
