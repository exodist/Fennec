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
/;

use List::Util qw/shuffle/;
use Time::HiRes qw/time/;
use Benchmark qw/timeit :hireswallclock/;

Accessors qw/files p_files p_tests threader ignore random pid parent_pid collector search default_asserts default_workflows/;

our $SINGLETON;

sub alias { $SINGLETON }

sub init {
    my $class = shift;
    my %proto = @_;

    croak( 'Fennec::Runner has already been initialized' )
        if $SINGLETON;

    my $random = defined $proto{ random } ? $proto{ random } : 1;
    my $handlers = delete $proto{ handlers } || [ 'TAP' ];

    my $collector_class = delete $proto{ collector } || 'Files';
    $collector_class = 'Fennec::Collector::' . $collector_class;
    eval "require $collector_class; 1" || die( @_ );
    my $collector = $collector_class->new( @$handlers );

    my $ignore = delete $proto{ ignore };
    my @files = FileLoader->find_types( delete $proto{ filetypes }, delete $proto{ files });
    @files = grep {
        my $file = $_;
        !grep { $file =~ $_ } @$ignore
    } @files if $ignore and @$ignore;
    die ( "No Fennec files found" )
        unless @files;
    @files = shuffle @files if $random;

    $proto{ p_files } = 2 unless defined $proto{ p_files };
    $proto{ p_tests } = 2 unless defined $proto{ p_tests };

    $SINGLETON = bless(
        {
            %proto,
            random      => $random,
            files       => \@files,
            collector   => $collector,
            threader    => Parallel::Runner->new( $proto{ p_files }) || die( "No threader" ),
            parent_pid  => $$,
            pid         => $$,
        },
        $class
    );
}

sub start {
    my $self = shift;

    $self->collector->start;
    $self->threader->iteration_callback( sub { $self->collector->cull });

    for my $file ( @{ $self->files }) {
        $self->threader->run( sub {
            try {
                my $workflow = Fennec::Workflow->new(
                    $file->filename,
                    method => sub { shift->file->load },
                    file => $file,
                )->_build_as_root;

                try {
                    $workflow->run_sub_as_current( $_ )
                        for Fennec::Workflow->build_hooks();
                }
                catch {
                    Diag->new( "build_hook error: $_" )->write
                };

                my $testfile = $workflow->testfile;
                return Result->skip_workflow( $testfile )
                    if $testfile->skip;

                try {
                    $workflow->build_children;
                    my $benchmark = timeit( 1, sub {
                        $workflow->run_tests( $self->search )
                    });
                }
                catch {
                    $testfile->threader->finish;
                    Result->fail_workflow( $testfile, $_ );
                };
            }
            catch {
                Result->fail_testfile( $file, $_ );
            };
        }, 1 );
    }
    $self->threader->finish;
    $self->collector->finish;
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

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
