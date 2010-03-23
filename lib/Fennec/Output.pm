package Fennec::Output;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Util::Abstract;
use Fennec::Runner;

Accessors qw/ stdout stderr workflow /;

sub workflow_stack {
    my $self = shift;
    unless ( $self->{ workflow_stack }) {
        my $current = $self->workflow;
        return undef unless $current;
        my @out = ( $current->name );
        while (( $current = $current->parent ) && $current->isa( 'Fennec::Workflow' )) {
            print "Current: $current\n";
            push @out => $current->name;
        }
        $self->{ workflow_stack } = [ reverse @out ];
    }
    return $self->{ workflow_stack };
}

sub serialize {
    my $self = shift;
    return {
        data => {
            %$self,
            workflow => undef,
            workflow_stack => $self->workflow_stack,
        },
        bless => ref( $self ),
    };
}

sub write {
    my $self = shift;
    Runner->collector->write( $self );
}

1;
