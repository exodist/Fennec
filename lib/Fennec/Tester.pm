package Fennec::Tester;
use strict;
use warnings;

use Fennec::TestBuilderImposter;
use IO::Socket::UNIX;
use Fennec::Result;
use Fennec::Util qw/add_accessors/;
use Cwd          qw/cwd/;
use File::Temp   qw/tempfile/;
use Scalar::Util qw/blessed/;
use List::Util   qw/shuffle/;
use File::Find   qw/find/;
use Carp         qw/croak confess/;

our @CARP_NOT = qw/Fennec::Test Fennec::TestHelper Fennec::Plugin/;
our $SINGLETON;

add_accessors qw/no_load bad_files ignore inline case set test random/;

sub import {
    my $class = shift;
    my %proto = @_;

    return unless $proto{ run };
    $class->new(%proto)->run;
}

sub get { goto &new };

# XXX This could stand some cleanup.
sub new {
    my $class = shift;
    return $SINGLETON if $SINGLETON;

    my %proto = @_;

    # TODO put this into a method?
    # Create socket
    my ( $fh, $socket_file ) = tempfile( cwd() . "/.test-suite.$$.XXXX", UNLINK => 1 );
    require IO::Socket::UNIX;
    close( $fh ) || die( $! );
    unlink( $socket_file );
    my $socket = IO::Socket::UNIX->new(
        Listen => 1,
        Local => $socket_file,
    ) || die( $! );

    # This was pulld out of an object method,
    # but it probably does belong in one.
    my $config;
    my $root = $proto{ root } ||$class->root;
    my $conf_file = $root . "/.fennec";
    if ( -f $conf_file ) {
        $config = eval { require $conf_file }
            || croak( "Error loading config file: $@" );
        croak( "config file did not return a hashref" )
            unless ref( $config ) eq 'HASH';
    }

    $SINGLETON = bless(
        {
            ignore => [],
            bad_files => [],
            parent_pid => $$,
            pid => $$,
            socket => $socket,
            _socket_file => $socket_file,
            tests => {},
            failures => [],
            root => $root,
            random => 1,
            # proto takes priority over config
            $config ? (%$config) : (),
            %proto,
        },
        $class
    );

    $SINGLETON->_init_output;

    $SINGLETON->find_files
        unless $SINGLETON->files;

    return $SINGLETON;
}

sub failures {
    my $class = shift;
    my $self = $class->get;
    push @{ $self->{ failures }} => @_ if @_;
    return @{ $self->{ failures }};
}

sub root {
    my $class = shift;
    my $self = $class if blessed( $class );

    return $self->{ root } if $self and $self->{ root };

    my $cd = cwd();
    my $root;
    do {
        $root = $cd if $class->_looks_like_root( $cd );
    } while !$root && $cd =~ s,/[^/]*$,,g && $cd;

    $self->{ root } = $root if $self;
    return $root;
}

sub files {
    my $self = shift;

    unless ( $self->{ files }) {
        my $root = $self->root;
        my @files;
        my $wanted = sub {
            no warnings 'once';
            my $file = $File::Find::name;
            return unless $file =~ m/\.pm$/;
            return if grep { $file =~ $_ } @{ $self->ignore };
            push @files => $file;
        };
        find( $wanted, "$root/ts", $self->inline ? ( "$root/lib" ) : () );
        $self->{ files } = \@files;
    }

    return $self->{ files };
}

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

sub pid {
    my $self = shift;
    return $$;
}

sub parent_pid {
    my $self = shift;
    return $self->{ parent_pid };
}

sub is_parent {
    my $self = shift;
    return ( $self->pid == $self->parent_pid ) ? 1 : 0;
}

sub is_running {
    my $self = shift;
    ($self->{ is_running }) = @_ if @_;
    return $self->{ is_running };
}

sub output_handlers {
    my $self = shift;
    push @{ $self->{ output_handlers }} => @_ if @_;
    return @{ $self->{ output_handlers }};
}

sub result {
    my $self = shift;
    my ($result) = @_;

    croak( "Testing has not been started" )
        unless $self->is_running;

    croak( "result() takes a Fennec::Result object" )
        unless $result
           and blessed( $result )
           and $result->isa( 'Fennec::Result' );

    return $self->_handle_result( $result )
        if $self->is_parent;

    confess( "This should not happen...", $self );

    $self->_send_result( $result );
}

sub diag {
    my $self = shift;
    for my $plugin ( $self->output_handlers ) {
        $plugin->diag( @_ );
    }
}

sub run {
    my $self = shift;
    croak "Already running"
        if $self->is_running;
    croak "run() may only be run from the parent process."
        unless $self->is_parent;

    $self->_load_files unless $self->no_load;

    $self->is_running( 1 );
    my $listen = $self->_socket;

    for my $test ( shuffle values %{ $self->tests }) {
        $self->test( $test );
        $self->diag( "Running test class " . ref($test) );
        $test->run( $self->case, $self->set );
        $self->test( undef );
    }

    $_->finish for $self->output_handlers;
    return 0 if (@{ $self->bad_files });
    return !$self->failures;
}

sub _init_output {
    my $self = shift;
    my $plugins = delete $self->{ output } || [ 'TAP', 'Database' ];
    $plugins = [ $plugins ] unless ref $plugins eq 'ARRAY';
    my @loaded;
    for my $plugin ( @$plugins ) {
        my $pclass = 'Fennec::Output::' . $plugin;
        eval "require $pclass" || die( $@ );
        push @loaded => $pclass->new;
    }
    $self->{ output_handlers } = \@loaded;
}

sub _handle_result {
    my $class = shift;
    my ($result) = @_;
    confess( "No result provided" )
        unless $result;
    confess( "Invalid result" )
        unless blessed($result) and $result->isa('Fennec::Result');

    $_->result( $result ) for $class->get->output_handlers;

    # Add failures to the list of failures.
    $class->get->failures($result) unless $result->result;
}

sub _send_result {
    # This will be used to serialize and send all results to the main process.
    confess( "Forking not yet implemented" );
}

sub _socket_file {
    my $self = shift;
    return $self->{ _socket_file },
}

sub _socket {
    my $self = shift;
    return $self->{ socket } if $$ == $self->parent_pid;

    # If we are in a new child clear existing sockets and make new ones
    unless ( $$ == $self->pid ) {
        delete $self->{ socket };
        delete $self->{ client_socket };
        $self->pid( 1 ); #Set pid.
    }

    $self->{ client_socket } ||= IO::Socket::UNIX->new(
        Peer => $self->_socket_file,
    );

    return $self->{ client_socket };
}

sub _load_files {
    my $self = shift;
    for my $file ( @{ $self->files }) {
        eval { require $file }
            || push @{ $self->bad_files } => [ $file, $@ ];
    }
}

sub _looks_like_root {
    my $class = shift;
    my ( $dir ) = @_;
    return unless $dir;
    return 1 if -e "$dir/.fennec";
    return 1 if -d "$dir/ts";
    return 1 if -d "$dir/t" && -d "$dir/lib";
    return 1 if -e "$dir/Build.PL";
    return 1 if -e "$dir/Makefile.PL";
    return 1 if -e "$dir/test.pl";
    return 0;
}

sub DESTROY {
    my $self = shift;
    my $socket = $self->_socket;
    close( $socket ) if $socket;
    unlink( $self->_socket_file ) if $self->is_parent;
}

1;

__END__

=pod

=head1 NAME

Fennec::Tester - The core of Fennec

=head1 DESCRIPTION

This is the class that kicks off the testing.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 CONSTRUCTOR OPTIONS

    my $tester = Fennec::Tester->new( option => 'value' );

=over 4

=item no_load => BOOL

Do not load the test files.

=item ignore => [ qr{}, qr{}, ... ]

When searching for files skip any that match any of these expressions.

=item inline => BOOL

Look for inline tests (see L<Fennec::Inline>)

=item files => [ './test1.pm', './test2.pm', ... ]

Specify test files to use.

=item case => NAME

Only run the specified case in each test file.

=item set => NAME

Only runt he specified set in each case.

=back

=head1 CLASS METHODS

=over 4

=item $class->import()

=item $class->import( 'run' )

=item $class->import( 'run', 'inline' )

Called automatically when you do:

    use Fennec::Tester @ARGS;

If 'run' is the first argument tests will automatically be found and run. If
the second argument is true inline tests will also be found.

=item $singleton = $class->new( %params )

Create a new instance. See the CONSTRUCTOR OPTIONS section above for more
details. Fennec::Tester is a singleton, that means that the first call will
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

=item $obj->inline()

Simple accessor to construction arg.

=item $obj->case()

Simple accessor to construction arg.

=item $obj->set()

Simple accessor to construction arg.

=item $obj->bad_files()

Returns an arrayref of files that died during require. Each item is an arrayref
with the filename and error returned.

=item @failures = $obj->failures( @add_failures )

Add or retrieve failures. Failures should be L<Fennec::Result> objects.

=back

=head1 OBJECT METHODS

These are methods that are mroe than simple accessors.

=over 4

=item $dir = $obj->root()

Find and retun the path to the project root directory.

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
directly. If you are witing a plugin please see L<Fennec::Plugin> or the
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
