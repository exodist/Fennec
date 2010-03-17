package Fennec::Runner;
use strict;
use warnings;

use base 'Fennec::Base';
use Fennec::Handler::Root;
use Fennec::Test;
use Fennec::Test::File;
use Fennec::Util::Accessors;
use Fennec::Util::Threader;
use Fennec::Group::Root;
use Fennec::Result;
use Carp;
use List::Util qw/shuffle/;
use Benchmark qw/timeit :hireswallclock/;

Accessors qw/handler files p_files p_tests threader ignore random pid parent_pid/;

our $SINGLETON;

sub alias { $SINGLETON }

sub new {
    my $class = shift;
    my %proto = @_;

    croak( 'Fennec::Runner has already been initialized' )
        if $SINGLETON;

    my $random = defined $proto{ random } ? $proto{ random } : 1;
    my $handlers = delete $proto{ handlers } || [ 'TAP' ];
    my $handler = Fennec::Handler::Root->new( @$handlers );

    my $ignore = delete $proto{ ignore };
    my $files = File->find_types( delete $proto{ filetypes }, delete $proto{ files });
    $files = [
        grep {
            my $file = $_;
            !grep { $file =~ $_ } @$ignore
        } @$files
    ] if $ignore and @$ignore;
    $files = [ shuffle( @$files )] if $random;

    $SINGLETON = bless(
        {
            %proto,
            random      => $random,
            files       => $files,
            handler     => $handler,
            threader    => Threader->new( $proto{ p_files }),
            parent_pid  => $$,
            pid         => $$,
        },
        $class
    );
}

sub start {
    my $self = shift;
    $self->handler->start;

    for my $file ( @{ $self->files }) {
        $self->threader->thread( sub {
            try {
                my $group = Fennec::Group::Root->new(
                    $file->filename,
                    method => sub { $self->file->load },
                    file => $file,
                )->build;

                my $test = $group->test;
                return Result->skip_item( $test )
                    if $test->skip;

                try {
                    $group->build_children;
                    $group->run_tests;
                }
                catch {
                    Result->fail_item( $test, $_ );
                };
            }
            catch {
                Result->fail_item( $file, $_ );
            };
        }, 1 );
    }

    $self->handler->finish;
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

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
