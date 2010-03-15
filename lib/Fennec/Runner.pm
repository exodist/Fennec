package Fennec::Runner;
use strict;
use warnings;

use base 'Fennec::Base';
use Fennec::Handler::Root;
use Fennec::Test;
use Fennec::Test::File;
use Fennec::Util::Accessors;
use Fennec::Util::Threader;
use Carp;
use List::Util qw/shuffle/;
use Benchmark qw/timeit :hireswallclock/;

Accessors qw/handler files p_files p_tests current threader ignore random pid parent_pid/;

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
            local $self->{ current };
            my @failures;
            $self->handler->push_failures_list( \@failures );
            try {
                $self->current( Test->new_from_file( $file ));
                $self->current->skip
                    ? Result->skip_item( $self->current )
                    : $self->current->run;
                @failures ? Result->fail_item( $self->current, @failures . " failures" )
                          : Result->pass_item( $self->current )
            }
            catch {
                Result->fail_item( $file, $_ );
            }
            $self->handler->pop_failures_list( \@failures );
        }, 1 )
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
