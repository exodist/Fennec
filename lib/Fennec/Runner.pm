package Fennec::Runner;
use strict;
use warnings;

use base 'Fennec::Base';
use Fennec::Test;
use Fennec::File;
use Fennec::Collector;
use Fennec::Util::Accessors;
use Fennec::Workflow::Root;
use Fennec::Output::Result;
use Try::Tiny;
use Parallel::Runner;
use Carp;
use List::Util qw/shuffle/;
use Time::HiRes qw/time/;
use Benchmark qw/timeit :hireswallclock/;

Accessors qw/files p_files p_tests threader ignore random pid parent_pid collector/;

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
    my @files = File->find_types( delete $proto{ filetypes }, delete $proto{ files });
    @files = grep {
        my $file = $_;
        !grep { $file =~ $_ } @$ignore
    } @files if $ignore and @$ignore;
    croak( "No Fennec files found" )
        unless @files;
    @files = shuffle @files if $random;

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

    $self->prepare;
    $self->threader->iteration_callback( sub { $self->collector->cull });
    $self->collector->start;

    for my $file ( @{ $self->files }) {
        $self->threader->run( sub {
            try {
                my $workflow = Fennec::Workflow::Root->new(
                    $file->filename,
                    method => sub { shift->file->load },
                    file => $file,
                )->build;

                my $test = $workflow->test;
                return Result->skip_workflow( $test )
                    if $test->skip;

                try {
                    $workflow->build_children;
                    my $benchmark = timeit( 1, sub {
                        $workflow->run_tests
                    });
                    Result->pass_workflow( $workflow, benchmark => $benchmark );
                }
                catch {
                    Result->fail_workflow( $test, $_ );
                };
            }
            catch {
                print "File error $file, $_\n";
                Result->fail_file( $file, $_ );
            };
        }, 1 );
    }

    $self->threader->finish;
    $self->collector->finish;
    $self->cleanup;
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

sub testdir { Fennec::File->root . "/_test" }

sub prepare {
    my $self = shift;
    $self->cleanup;
    my $path = $self->testdir;
    mkdir( $path ) unless -d $path;
}

sub cleanup {
    my $class = shift;
    return unless -d $class->testdir;
    opendir( my $TDIR, $class->testdir ) || die( $! );
    for my $file ( readdir( $TDIR )) {
        next if $file =~ m/^\.+$/;
        next if -d $file;
        unlink( $file );
    }
    closedir( $TDIR );
    rmdir( $class->testdir ) || warn( "Cannot cleanup test dir: $!" );
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
