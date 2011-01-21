package Test::Workflow::Test;
use strict;
use warnings;

use Fennec::Util qw/accessors/;

accessors qw/setup tests teardown around/;

sub new {
    my $class = shift;
    my %params = @_;
    return bless({
        setup    => $params{setup}    || [],
        tests    => $params{tests}    || [],
        teardown => $params{teardown} || [],
        around   => $params{around}   || [],
    }, $class );
}

sub run {
    my $self = shift;
    my ( $instance ) = @_;
    $_->run( $instance ) for @{ $self->setup };
    for my $test ( @{ $self->tests }) {
        my $outer = sub { $test->run( $instance )};
        for my $around ( @{ $self->around }) {
            my $inner = $outer;
            $outer = sub { $around->run( $instance, $inner )};
        }
        $outer->();
    }
    $_->run( $instance ) for @{ $self->teardown };
}

1;
