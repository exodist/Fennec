package Fennec::Handler::TAP;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use TAP::Parser;

use base 'Fennec::Handler';

sub new {
    my $class = shift;
    bless({
        count => 0,
        exit => 0,
    }, $class );
}

sub handle {
    my $self = shift;
    my ( $handle, $pid, $data ) = @_;
    print STDOUT $data if $handle eq 'STDOUT';
    print STDERR $data if $handle eq 'STDERR';

    my $parser = TAP::Parser->new({ source => $data });
    while ( my $result = $parser->next ) {
        $self->{count}++ if $result->is_test;
        $self->{exit}++ unless $result->is_ok;
    }
}

sub exit {
    my $self = shift;
    print STDOUT "1.." . $self->{count} . "\n";
    exit $self->{exit};
}

1;
