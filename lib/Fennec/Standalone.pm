package Fennec::Standalone;
use strict;
use warnings;
require Fennec;
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
        *{ $caller . '::finish' } = sub { $runner->finish }
    }

    my $workflow = Fennec::Workflow->new(
        $caller,
        method => sub { $Fennec::TEST_CLASS = $caller },
        file => $file,
    )->_build_as_root;

    $runner->add_finish_hook( sub {
        my $self = shift;
        $self->process_workflow( $workflow );
    });
    $runner->reset_benchmark;

    no warnings 'redefine';
    *Fennec::Workflow::has_current = sub { 1 };
    *Fennec::Workflow::current = sub { $workflow };
    *Fennec::Workflow::depth = sub { 1 };
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
