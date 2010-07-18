package Fennec::Standalone;
use strict;
use warnings;
require Fennec;
use Fennec::Util::TBOverride;
use Fennec::Runner qw/add_finish_hook/;
use Fennec::Workflow;
use Fennec::Output::Result;

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
        *{ $caller . '::done_testing' } = sub { $runner->finish };
        *{ $caller . '::use_or_skip' } = sub(*;@) {
            my ($package, @args) = @_;
            unless (eval { Fennec::_use_or_skip($package, @args); 1 }) {
                print "Skipping\n";
                _skip( [caller], $@ );
                $runner->finish;
                exit 0;
            }
        };
        *{ $caller . '::require_or_skip' } = sub(*) {
            my ($package) = @_;
            unless (eval { Fennec::_require_or_skip($package); 1 }) {
                _skip( [caller], $@ );
                $runner->finish;
                exit 0;
            }
        };
    }

    add_finish_hook( sub {
        my $self = shift;
        $self->process_workflow(
            $runner->_init_workflow( $caller )
        );
    });
    $runner->reset_benchmark;
}

sub _skip {
    my ( $caller, $message ) = @_;
    die( $@ ) unless $message =~ m/SKIP:\s*(.*)/;
    Fennec::Output::Result->new(
        pass => 0,
        skip => $1,
        line => $caller->[1],
        file => $caller->[2],
        name => $caller->[2],
    )->write;
}

1;

=head1 NAME

Fennec::Standalone - Standalone Fennec test module

=head1 DESCRIPTION

Use this instead of L<Fennec> when writing standlone tests. Creates a runner,
starts a root workflow, provides done_testing() to finish things up.

=head1 DEVELOPER API

B<This documentation contains developer documentation for those wishing to
develop Fennec.> For usage information see the L<Fennec::Manual>.

=over 4

=item import( runner => {...}, %fennec_args )

import() will initialize a runner, call fennec::import(), and override some of
the functions exported by fennec to work in a standalone setting.

You can specify arguments for the runner with runner => {...}. Any other
arguments will be passed along to the L<Fennec> module.

=back

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
