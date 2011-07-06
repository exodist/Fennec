package Fennec::Listener::TB::Result;
use strict;
use warnings;

use Fennec::Util qw/accessors/;

accessors qw/raw/;

sub new {
    my $class = shift;
    my ( $TAP ) = @_;
    my $self = bless {}, $class;
    chomp( $TAP );
    $self->raw( $TAP );

    return $self;
}

sub is_plan {
    my $self = shift;
    return 1 if $self->raw =~ m/^1\.\.\d+/;
    return 0;
}

sub is_comment {
    my $self = shift;
    return 1 unless $self->is_plan || $self->is_test;
    return 0;
}

sub is_test {
    my $self = shift;
    return 0 if $self->raw =~ m/^#/;
    return 1 if $self->raw =~ m/^\s*(not\s+)?(ok)/;
    return 0;
}

sub is_todo {
    my $self = shift;
    return unless $self->is_test;
    my ( $reason ) = ($self->raw =~ m/# TODO (.*)$/);
    return $reason || 0;
}

sub is_skip {
    my $self = shift;
    return unless $self->is_test;
    my ( $reason ) = ($self->raw =~ m/# SKIP (.*)$/);
    return $reason || 0;
}

sub is_pass {
    my $self = shift;
    return unless $self->is_test;
    my ( $fail ) = ( $self->raw =~ m/^(not\s+)?ok/ );
    return !$fail;
}

sub is_fail {
    my $self = shift;
    return unless $self->is_test;
    return !$self->is_pass;
}

sub is_ok {
    my $self = shift;
    return unless $self->is_test;
    return 1 if $self->is_pass;
    return 1 if $self->is_todo || $self->is_skip;
    return 0;
}

sub render {
    my $self = shift;

    unless ($self->is_test) {
        my $line = $self->raw;
        $line =~ s/^\s*#\s*//;
        return "# $line\n";
    }

    my $line = $self->raw;
    my ( $fail, $append );

    $fail = $1 if $line =~ s/^\s*(not\s+)//;

    $line =~ s/^\s*(ok)\s*\d*\s*//;

    $append = $1 if $line =~ s/(#\s*(?:TODO|SKIP).*)$//;

    my $info = $line;

    no warnings 'uninitialized';
    return "${fail}ok $info $append\n";
}

1;
