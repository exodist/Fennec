package Fennec::Standalone;
use strict;
use warnings;
require Fennec;
use Fennec::Util::TBOverride;
use Fennec::Runner;
use Fennec::Workflow;

sub import {
    my $class = shift;
    my %proto = @_;
    my $runner_proto = delete $proto{ runner };
    my( $caller, $line, $file ) = caller;
    my $runner = 'Fennec::Runner'->init( %$runner_proto );

    $runner->start;
    srand( $runner->seed );
    Fennec->import( %proto, caller => [ $caller, $line, $file ]);

    {
        no warnings 'redefine';
        no strict 'refs';
        *{ $caller . '::done_testing' } = sub { $runner->finish }
    }

    $runner->add_finish_hook( sub {
        my $self = shift;
        $self->process_workflow(
            $runner->_init_workflow( $caller )
        );
    });
    $runner->reset_benchmark;
}

1;

=head1 NAME

Fennec::Standalone - Standalone Fennec test module

=head1 DESCRIPTION

Use this instead of L<Fennec> when writing standlone tests. Creates a runner,
starts a root workflow, provides done_testing() to finish things up.

=head1 SEE ALSO

L<Fennec::Manual::Quickstart>

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
