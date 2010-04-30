package Fennec::Collector;
use strict;
use warnings;

use Fennec::Util::Accessors;
use Fennec::Util::Abstract;

Accessors qw/handlers/;
Abstract  qw/cull write/;

sub new {
    my $class = shift;
    my @handlers;
    for my $hclass ( @_ ) {
        my $fhclass = 'Fennec::Handler::' . $hclass;
        eval "require $fhclass; 1" || die ( $@ );
        push @handlers => $fhclass->new();
    }
    my $self = bless( { handlers => \@handlers }, $class );
    $self->init if $self->can( 'init' );
    return $self;
}

sub start {
    my $self = shift;
    $_->start for @{ $self->handlers };
}

sub finish {
    my $self = shift;
    $self->handle_output;
    $_->finish for @{ $self->handlers };
}

sub starting_file {
    my $self = shift;
    my ( $filename ) = @_;
    $_->starting_file( $filename ) for @{ $self->handlers };
}

sub handle_output {
    my $self = shift;
    my @objs = @_ ? @_ : $self->cull;
    my @bailouts;
    for my $obj ( sort { $a->timestamp <=> $b->timestamp } @objs ) {
        push @bailouts => $obj
            if $obj->isa( 'Fennec::Output::BailOut' );
        for my $handler ( @{ $self->handlers }) {
            $handler->handle( $obj );
        }
    }
    Runner->bail_out( \@bailouts ) if @bailouts;
}


1;

=head1 NAME

Fennec::Collector - Base class for fennec output collectors.

=head1 DESCRIPTION

Fennec runs tests in parallel. All results must be sent from the child
processes to the parent process. That is the collectors job.

=head1 SEE ALSO

=over 4

=item L<Fennec::Manual::Collectors>

=back

=head1 API

=head2 ABSTRACT METHODS

=over 4

=item $obj->write( $output )

Write an output object so that it can be found by the parent process. The write
may occur in a process other than the parent.

=item @outputs = $obj->cull()

Read the written output objects. This read will be done in the parent process.

=back

=head2 CLASS METHODS

=over 4

=item $obj = $class->new( @handler_package_tails )

Create a new instance. @handler_package_taisl should be a list of handler
packages, but only the part of the package name after 'Fennec::Handler::'.
These packages will be loaded and instansiated.

=back

=head2 OBJECT METHODS

=over 4

=item $handlers = $obj->handlers()

=item $obj->handlers( \@handlers )

Get or set the list of handler objects.

=item $obj->start()

Tell all handlers to start.

=item $obj->finish()

Calls handle_output, then tells all handlers to finish.

=item $obj->handle_output()

Culls all output objects and sends them to the handlers. Also handles bail_out
objects.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
