package TEST::Fennec::Workflow::Methods;
use strict;
use warnings;

use Fennec workflows => [ 'Methods' ],
           sort => 1,
           no_fork => 1;

use Fennec::Util::Accessors;

Accessors qw/ did_run_setup did_run_tests did_run_teardown /;

our $ORDER = 1;

sub setup {
    my $self = shift;
    $self->did_run_setup( $ORDER++ );
}

sub test_method {
    my $self = shift;
    $self->did_run_tests( $ORDER++ );
}

sub teardown {
    my $self = shift;
    $self->did_run_teardown( $ORDER++ );
}

tests 'Z - Run this last' => sub {
    my $self = shift;

    is( $self->did_run_setup, 1, "Ran setup first" );
    is( $self->did_run_tests, 2, "Ran test second" );
    is( $self->did_run_teardown, 3, "Ran teardown last" );
};

1;
