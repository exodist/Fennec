package Fennec::Handler::TAP;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use TAP::Parser;
use POSIX ":sys_wait_h";
use Data::Dumper;

accessors qw/buffer ready/;

use base 'Fennec::Handler';

sub new {
    my $class = shift;
    bless({
        count => 0,
        exit => 0,
        buffer => {},
        ready => [],
    }, $class );
}

sub handle {
    my $self = shift;
    my %params = @_;
    my $parser = TAP::Parser->new({ source => $params{data} });

    while ( my $result = $parser->next ) {
        $self->{count}++ if $result->is_test;
        $self->{exit}++ unless $result->is_ok;
        $self->buffer_result( $result, %params );
    }

    $self->print_ready;
}

sub reap {
    my $self = shift;
    for my $pid (keys %{$self->buffer}) {
        my $ret = waitpid( $pid, WNOHANG );
        next unless $ret < 0 || $ret == $pid;
        push @{$self->ready} => delete $self->buffer->{$pid};
    }

    $self->print_ready;
}

sub flush {
    my $self = shift;

    push @{$self->ready} => delete $self->buffer->{$_}
        for keys %{ $self->buffer };

    $self->print_ready;
}

sub buffer_result {
    my $self = shift;
    my ( $result, %params ) = @_;
    my $usehandle = $params{handle};
    $usehandle = 'STDOUT'
        if $result->is_comment
        && $params{handle} eq 'STDERR'
        && $ENV{TEST_VERBOSE};

    my $buffer = $self->get_buffer( %params, usehandle => $usehandle );
    push @{$buffer->{results}} => $result;
}

sub get_buffer {
    my $self = shift;
    my ( %params ) = @_;

    my $existing = $self->buffer->{$params{pid}};
    my $desired = {
        package   => $params{package},
        linenum   => $params{ln},
        usehandle => $params{usehandle},
        results   => [],
    };

    my $match = $existing
        && $existing->{package} eq $desired->{package}
        && $existing->{linenum} eq $desired->{linenum}
        && $existing->{usehandle} eq $desired->{usehandle};

    return $existing if $match;

    push @{$self->ready} => $existing if $existing;
    $self->buffer->{$params{pid}} = $desired;

    return $desired;
}

sub print_ready {
    my $self = shift;
    for my $set ( @{$self->ready}) {
        for my $result ( @{$set->{results}}) {
            if ( $set->{usehandle} eq 'STDOUT' ) {
                print STDOUT $result->raw . "\n";
            }
            elsif( $set->{usehandle} eq 'STDERR' ) {
                print STDERR $result->raw . "\n";
            }
        }
    }
    $self->ready([]);
}

sub exit {
    my $self = shift;
    my ( $exit ) = @_;
    $exit ||= $self->{exit} || 0;
    $self->flush();
    print STDOUT "1.." . $self->{count} . "\n" unless $exit;
    exit $exit;
}

1;

__END__

        no strict 'refs';

