package Fennec::Runner;
use strict;
use warnings;

use Fennec::Util::Alias qw/
    Fennec::TestFile
    Fennec::Collector
    Fennec::Workflow
/;

use Fennec::Util::Accessors;
use Try::Tiny;
use Parallel::Runner;
use Carp;

use Fennec::Util::Alias qw/
    Fennec::FileLoader
    Fennec::Output::Result
    Fennec::Output::Diag
    Fennec::Output::Note
    Fennec::Output::BailOut
    Fennec::Config
    Fennec::Runner::Proto
/;

use Digest::MD5 qw/md5_hex/;
use List::Util  qw/shuffle/;
use Time::HiRes qw/time/;
use Benchmark   qw/timeit :hireswallclock/;

Accessors qw/
    files parallel_files parallel_tests threader ignore random pid parent_pid
    collector search default_asserts default_workflows _benchmark_time seed
    _started _finished finish_hooks bail_out
/;

our $SINGLETON;

sub alias { $SINGLETON }

sub init {
    my $class = shift;
    croak( 'Fennec::Runner has already been initialized' )
        if $SINGLETON;

    my $seed = $ENV{ FENNEC_SEED } || (( unpack "%L*", md5_hex( time * $$ )) ^ $$ );
    srand( $seed );

    $SINGLETON = Proto->new( @_, seed => $seed )
                      ->rebless($class);

    return $SINGLETON;
}

sub run_tests {
    my $self = shift;
    $self->start;

    for my $file ( @{ $self->files }) {
        my $counter = 0;
        my $all = @{ $self->files };

        srand( $self->seed );
        $self->threader->run( sub {
            $counter++;
            Note->new( stdout => ["Running file $counter/$all:", "\t" . $file->filename ])->write;
            try {
                $self->reset_benchmark;
                my $workflow = Fennec::Workflow->new(
                    $file->filename,
                    method => sub { shift->file->load },
                    file => $file,
                )->_build_as_root;

                $self->process_workflow( $workflow );
            }
            catch {
                use Data::Dumper;
                if ( $_ =~ m/SKIP:\s*(.*)/ ) {
                    Result->new(
                        pass => 0,
                        skip => $1,
                        name => $file->filename || "unknown file",
                    )->write;
                }
                else {
                    Result->new(
                        pass => 0,
                        name => $file->filename || "unknown file",
                        stderr => [ $_ ],
                    )->write;
                }
            };
        }, 1 );
    }

    $self->finish;
}

sub process_workflow {
    my $self = shift;
    my ( $workflow ) = @_;

    $self->reset_benchmark;
    try {
        $workflow->run_sub_as_current( $_ )
            for Fennec::Workflow->build_hooks();
    }
    catch {
        Diag->new( stderr => [ "build_hook error: $_" ])->write
    };

    my $testfile = $workflow->testfile;
    return Result->skip_workflow( $testfile )
        if $testfile->fennec_meta->skip;

    try {
        $workflow->build_children;
        my $benchmark = timeit( 1, sub {
            $self->reset_benchmark;
            $workflow->run_tests( $self->search )
        });
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
    $self->_started(1);
    Diag->new(
        stderr => [
            "** Reproduce this test order with this environment variable:",
            "** FENNEC_SEED='@{[ $self->seed ]}'",
        ],
    )->write;
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
Did you forget to run finish() in a standalone test file?
EOT
    }
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
