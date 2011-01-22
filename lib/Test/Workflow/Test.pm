package Test::Workflow::Test;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use List::Util qw/shuffle/;

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
    my @tests = @{ $self->tests };
    @tests = sort @tests if "$sort" =~ /^sort/;
    @tests = shuffle @tests if "$sort" =~ /^rand/;
    @tests = $sort->( @tests ) if ref $sort eq 'CODE';

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
