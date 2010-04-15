package Fennec::Output;
use strict;
use warnings;

use Fennec::Util::Accessors;
use Fennec::Util::Abstract;
use Fennec::Util::Alias qw/
    Fennec::Runner
/;

Accessors qw/ stdout stderr _workflow testset timestamp /;

sub workflow_stack {
    my $self = shift;
    unless ( $self->{ workflow_stack }) {
        my $current = $self->workflow;
        return undef unless $current;
        my @out = ( $current->name );
        while (( $current = $current->parent ) && $current->isa( 'Fennec::Workflow' )) {
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
            _workflow => undef,
            testset => undef,
            workflow_stack => $self->workflow_stack,
        },
        bless => ref( $self ),
    };
}

sub write {
    my $self = shift;
    $self->timestamp( time ) unless $self->timestamp;
    Runner->collector->write( $self );
}

sub testfile {
    my $self = shift;
    return $self->{ testfile } if $self->{ test_file };

    if ( my $workflow = $self->workflow ) {
        return $workflow if $workflow->isa( 'Fennec::TestFile' );
        my $testfile = $workflow->testfile if $workflow->can( 'testfile' );
        return $testfile if $testfile;
    }
    return $self->{ testfile };
}

sub workflow {
    my $self = shift;
    unless( $self->_workflow ) {
        return unless $self->testset;
        $self->_workflow( $self->testset->workflow );
    }
    return $self->_workflow;
}

1;
