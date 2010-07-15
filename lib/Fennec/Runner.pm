package Fennec::Runner;
use strict;
use warnings;

use Fennec::Util::TBOverride;
use Fennec::Util::Accessors;
use Try::Tiny;
use Parallel::Runner;
use Carp;

use Fennec::Util::Alias qw/
    Fennec::Output::Diag
    Fennec::Output::Result
/;

use Digest::MD5 qw/md5_hex/;
use List::Util  qw/shuffle/;
use Time::HiRes qw/time/;
use base 'Exporter';

# Configuration items moved to require at bottom.

Accessors qw/ _benchmark_time _finished _started bail_out finish_hooks seed /;

our @EXPORT_OK = qw/add_config add_test_hook/;
our $SINGLETON;
our %CONFIG_OPTIONS;
our @TEST_HOOKS;

sub alias { $SINGLETON }
sub config_options { \%CONFIG_OPTIONS }

sub add_test_hook {
    push @TEST_HOOKS => @_;
}

sub add_config {
    my ( $name, @args ) = @_;

    croak "Runner already defines $name"
        if __PACKAGE__->can( $name );

    my %options = @args > 1
        ? @args
        : ( default => @args );

    $options{ env_override } = uc("FENNEC_$name")
        unless defined $options{ env_override }
            && $options{ env_override } ne '1';

    $options{ depends } = { map { $_ => 1 } @{ $options{ depends }} }
        if $options{ depends };

    $options{ name } = $name;

    no strict 'refs';
    Accessors $name;
    $CONFIG_OPTIONS{ $name } = \%options;
}

sub init {
    my $class = shift;
    my %in = @_;
    croak( 'Fennec::Runner has already been initialized' )
        if $SINGLETON;
    my $seed = $ENV{ FENNEC_SEED } || (( unpack "%L*", md5_hex( time * $$ )) ^ $$ );
    srand( $seed );
    my $data = { seed => $seed };

    for my $option ( values %CONFIG_OPTIONS ) {
        $class->_process_option( $option, \%in, $data, {} );
    }

    $SINGLETON = bless( $data, $class );
    return $SINGLETON;
}

# XXX TODO: Clean this up
sub _process_option {
    my $class = shift;
    my ( $option, $in, $data, $state ) = @_;
    my $name = $option->{ name };
    $state->{ $name } ||= 0;
    return if $state->{ $name } == 2;

    croak join( "\n",
        "Circular Dependencies detected:",
        map { $state->{ $_ } == 1 ? $_ : () } keys %$state
    ) if $state->{ $name } == 1;

    $state->{ $name } = 1;
    $class->_process_option(
        $CONFIG_OPTIONS{ $_ },
        $in,
        $data,
        $state
    ) for keys %{ $option->{ depends } || {} };
    $state->{ $name } = 2;

    my $value;
    $value = $ENV{ $option->{ env_override }}
        if $option->{ env_override };
    $value ||= $in->{ $name };

    if ( $option->{ default } && !defined $value ) {
        my $default = $option->{ default };
        my $ref = ref( $default ) || 'NONE';
        $value = $ref eq 'CODE'
            ? $option->{ default }->( $data )
            : $default;
    }

    croak "Option $name is required"
        if $option->{ required }
        && !defined $value;

    $value = $option->{ modify }->( $value, $data )
        if $option->{ modify };

    $data->{ $name } = $value;
}

sub run_tests {
    my $self = shift;
    $self->start;

    for my $file ( @{ $self->files }) {
        $self->collector->starting_file( $file->filename );

        srand( $self->seed );
        $self->threader->run( sub {
            $self->_test_thread( $file );
        }, 1 );
    }

    $self->finish;
}

sub _test_thread {
    my $self = shift;
    my ( $file ) = @_;

    try {
        my $test = $self->_init_file( $file )->fennec_new();
        my $root_workflow = $self->_init_workflow( $test )
        $_->( $self, $test ) for @TEST_HOOKS;
        $self->process_workflow( $root_workflow );
    }
    catch {
        if ( $_ =~ m/SKIP:\s*(.*)/ ) {
            Result->new(
                pass => 0,
                skip => $1,
                file => $file->filename || "unknown file",
                name => $file->filename || "unknown file",
            )->write;
        }
        else {
            Result->new(
                pass => 0,
                file => $file->filename || "unknown file",
                name => $file->filename || "unknown file",
                stderr => [ $_ ],
            )->write;
        }
    };
}

sub _init_file {
    my $self = shift;
    my ( $file ) = @_;
    $self->reset_benchmark;

    return $file->load;
}

sub _init_workflow {
    my $self = shift;
    my ( $test ) = @_;
    $test->fennec_meta->root_workflow->parent( $test );
    return $test->fennec_meta->root_workflow;
}

sub process_workflow {
    my $self = shift;
    my ( $workflow ) = @_;

    $self->reset_benchmark();
    return unless $workflow->run_build_hooks();

    my $testfile = $workflow->testfile;
    return Result->skip_workflow( $testfile )
        if $testfile->fennec_meta->skip;

    try {
        $workflow->build;
        $self->reset_benchmark;
        $workflow->run_tests( $self->search )
    }
    catch {
        $testfile->fennec_meta->threader->finish;
        Result->fail_workflow( $testfile, $_ );
    };
}

sub start {
    my $self = shift;
    $self->collector->start;
    $self->threader->iteration_callback( sub {
        $self->collector->handle_output;
        return unless $self->bail_out;
        $self->threader->killall(15)
    });
    $self->threader->reap_callback( \&_reap_callback );
    $self->_started(1);
    Diag->new(
        stderr => [
            "** Reproduce this test order with this environment variable:",
            "** FENNEC_SEED='@{[ $self->seed ]}'",
        ],
    )->write;
}

sub _reap_callback {
    my ( $status, $pid, $ret ) = @_;
    Result->new(
        pass => 0,
        name => "Child exit",
        stderr => [ "Child ($pid) exited with non-zero status(@{[$status >> 8]})!" ],
    )->write if $status;
    Result->new(
        pass => 0,
        name => "Wait status",
        stderr => [ "waitpid($pid) returned $ret!" ],
    )->write if $pid != $ret;
    return;
}

sub finish {
    my $self = shift;
    $self->$_() for @{ $self->finish_hooks || []};
    $self->threader->finish;
    $self->collector->finish;
    $self->_finished(1);
}

sub add_finish_hook {
    my $self = shift;
    push @{ $self->{ finish_hooks }} => @_;
}

sub pid_changed {
    my $self = shift;
    my $pid = $$;
    return 0 if $self->pid == $pid;
    return $pid;
}

sub is_parent {
    my $self = shift;
    return if $self->pid_changed;
    return ( $self->pid == $self->parent_pid ) ? 1 : 0;
}

sub is_subprocess {
    my $self = shift;
    return !$self->is_parent;
}

sub run_with_collector {
    my $self = shift;
    my ( $collector, $code ) = @_;
    local $self->{ collector } = $collector;
    return $code->();
}

sub reset_benchmark {
    my $self = shift;
    return $self->_benchmark_time( time )
}

sub benchmark {
    my $self = shift;
    my $old = $self->_benchmark_time;
    unless ($old) {
        $self->reset_benchmark;
        return;
    }
    my $new = $self->reset_benchmark;
    return [( $new - $old )];
}

sub DESTROY {
    my $self = shift;
    return if $self->is_subprocess;
    if( $self->_started && !$self->_finished ) {
        warn <<EOT;
Runner never finished!
Did you forget to run done_testing() in a standalone test file?
EOT
    }
}

# Load after class
require Fennec::Runner::Config;

1;

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
