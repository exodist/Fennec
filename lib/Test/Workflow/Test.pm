package Test::Workflow::Test;
use strict;
use warnings;

use Fennec::Util qw/accessors/;

accessors qw/setup tests teardown/;

sub new {
    my $class = shift;
    my %params = @_;
    return bless({
        setup    => $params{setup}    || [],
        tests    => $params{tests}    || [],
        teardown => $params{teardown} || [],
    }, $class );
}

sub run {
    my $self = shift;
    my ( $instance ) = @_;
    $_->run( $instance ) for @{ $self->setup    };
    $_->run( $instance ) for @{ $self->tests    };
    $_->run( $instance ) for @{ $self->teardown };
}

1;
