package Test::Workflow::Test;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use List::Util qw/shuffle/;
use Carp qw/cluck/;

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

sub debug_handler {
    my $self = shift;
    my ( $timeout, $instance ) = @_;

    my $data = {
        instance => $instance,
        test => $self,
    };

    return sub {
        require Data::Dumper;

        my $meta = $instance->TEST_WORKFLOW;
        $meta->ok->(0, "Long running process timeout");

        my $out = "Long running process timeout\n";

        $out .= "\ttimeout - $timeout\n\ttest - " . $self->name . "\n\n";

        {
            local $Data::Dumper::Maxdepth = 3;
            $out .= "Brief Dump: " . Data::Dumper::Dumper($data);
        }

        $out .= "Full Dump: " . Data::Dumper::Dumper($data);

        die $out;
    }
};

sub run {
    my $self = shift;
    my ( $instance ) = @_;

    my $run = $self->_wrap_tests( $instance );
    my $prunner = $instance->TEST_WORKFLOW->test_run;
    my $testcount = @{ $self->tests };

    return $prunner->( $run, $self, $instance ) if $prunner && $testcount == 1;

    $run->();
}

sub _timeout_wrap {
    my $self = shift;
    my ( $instance, $inner ) = @_;

    my $timeout = $instance->TEST_WORKFLOW->debug_long_running;
    return $inner unless $timeout;

    return sub {
        no warnings 'uninitialized';
        $SIG{ALRM} = $self->debug_handler( $timeout, $instance );
        alarm $timeout;
        $inner->();
        alarm 0;
        # At this point we have screwed up any other alarms, clear the handler
        $SIG{ALRM} = undef;
    };
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
            $outer = $self->_timeout_wrap( $instance, $outer );
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

__END__

=head1 NAME

package Test::Workflow::Test - A test block wrapped with setup/teardown
methods, ready to be run.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Test-Workflow is free software; Standard perl licence.

Test-Workflow is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
