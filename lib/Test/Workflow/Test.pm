package Test::Workflow::Test;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use List::Util qw/shuffle/;

accessors qw/setup tests teardown around block_name/;

sub new {
    my $class = shift;
    my %params = @_;
    return bless({
        setup      => $params{setup}      || [],
        tests      => $params{tests}      || [],
        teardown   => $params{teardown}   || [],
        around     => $params{around}     || [],
        block_name => $params{block_name} || ""
    }, $class );
}

sub name {
    my $self = shift;
    return $self->tests->[0]->name
        if @{ $self->tests } == 1;

    return $self->block_name;
}

sub run {
    my $self = shift;
    my ( $instance ) = @_;

    my $run = $self->_wrap_tests( $instance );
    my $prunner = $instance->TEST_WORKFLOW->test_run;
    my $testcount = @{ $self->tests };

    return $prunner->( $run ) if $prunner && $testcount == 1;

    $run->();
}

sub _wrap_tests {
    my $self = shift;
    my ( $instance ) = @_;

    my $sort = $instance->TEST_WORKFLOW->test_sort || 'rand';
    my @tests = Test::Workflow::order_tests( $sort, @{ $self->tests });

    return sub {
        $_->run( $instance ) for @{ $self->setup };
        for my $test ( @tests ) {
            my $outer = sub { $test->run( $instance )};
            for my $around ( @{ $self->around }) {
                my $inner = $outer;
                $outer = sub { $around->run( $instance, $inner )};
            }
            $outer->();
        }
        $_->run( $instance ) for @{ $self->teardown };
    };
}

1;
