package Test::Workflow::Test;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use List::Util qw/shuffle/;
use Carp qw/cluck/;

accessors qw/setup tests teardown around block_name is_wrap/;

sub new {
    my $class  = shift;
    my %params = @_;
    return bless(
        {
            setup      => $params{setup}      || [],
            tests      => $params{tests}      || [],
            teardown   => $params{teardown}   || [],
            around     => $params{around}     || [],
            block_name => $params{block_name} || "",
            is_wrap    => $params{is_wrap}    || 0,
        },
        $class
    );
}

sub name {
    my $self = shift;
    return $self->tests->[0]->name
        if @{$self->tests} == 1;

    return $self->block_name;
}

sub run {
    my $self = shift;

    my ($instance) = @_;

    my $run       = $self->_wrap_tests($instance);
    my $prunner   = $instance->TEST_WORKFLOW->test_run;
    my $testcount = @{$self->tests};

    return $run->() if $self->is_wrap;

    return $prunner->( $run, $self, $instance )
        if $prunner && $testcount == 1;

    $run->();
}

sub _wrap_tests {
    my $self = shift;
    my ($instance) = @_;

    my $sort = $instance->TEST_WORKFLOW->test_sort || 'rand';
    my @tests = Test::Workflow::order_tests( $sort, @{$self->tests} );

    my $wait = $instance->TEST_WORKFLOW->test_wait;
    my $pid  = $$;

    return sub {
        $_->run($instance) for @{$self->setup};
        for my $test (@tests) {
            my $outer = sub { $test->run($instance) };
            for my $around ( @{$self->around} ) {
                my $inner = $outer;
                $outer = sub { $around->run( $instance, $inner ) };
            }
            $wait->() if $wait && $test->can('is_wrap') && $test->is_wrap;
            $outer->();
        }
        $_->run($instance) for @{$self->teardown};
        $wait->() if $wait && $self->is_wrap;
    };
}

1;

__END__

=head1 NAME

Test::Workflow::Test - A test block wrapped with setup/teardown methods, ready
to be run.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Test-Workflow is free software; Standard perl license.

Test-Workflow is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
