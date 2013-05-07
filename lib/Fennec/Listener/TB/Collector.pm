package Fennec::Listener::TB::Collector;
use strict;
use warnings;

use Fennec::Listener::TB::Result;
use Fennec::Util qw/accessors/;
accessors qw/errors count buffer/;

sub new {
    my $class = shift;
    return bless(
        {
            errors => 0,
            count  => 0,
            buffer => {},
        },
        $class
    );
}

sub process {
    my $self = shift;
    my ($line) = @_;
    my ( $pid, $handle, $class, $file, $ln, $msg ) = split( "\0", $line );
    my $key = "$class $file $ln";

    my $result = Fennec::Listener::TB::Result->new($msg);
    return if $result->is_plan;

    $self->{count}++ if $result->is_test;
    $self->{errors}++ unless $result->is_ok;

    if ( $ENV{HARNESS_IS_VERBOSE} ) {
        print STDOUT $result->render;
    }
    else {
        if ( $handle eq 'STDERR' ) {
            print STDERR $result->render;
        }
        else {
            print STDOUT $result->render;
        }
    }
}

sub terminate {
    my $self = shift;
    for my $pid ( keys %{$self->buffer} ) {
        $self->flush($pid);
    }
    print "1.." . $self->count . "\n";
}

1;
