package Fennec::Output::Result;
use strict;
use warnings;

use base 'Fennec::Output';

use Fennec::Util::Accessors;
use Fennec::Runner;
use Fennec::Workflow;
use Try::Tiny;

our @WORKFLOW_OR_TEST_ACCESSORS = qw/ skip todo /;
our @WORKFLOW_ACCESSORS = qw/ name file line /;
our @SIMPLE_ACCESSORS = qw/ pass benchmark /;
our @PROPERTIES = (
    @WORKFLOW_ACCESSORS,
    @SIMPLE_ACCESSORS,
    @WORKFLOW_OR_TEST_ACCESSORS,
    qw/ stderr stdout workflow_stack test /,
);
our $TODO;

Accessors @SIMPLE_ACCESSORS;

sub TODO {
    my $class = shift;
    ($TODO) = @_ if @_;
    return $TODO;
}

sub fail { !shift->pass }

sub new {
    my $class = shift;
    print "New Result\n";
    my ( $pass, $workflow, %proto ) = @_;
    return bless(
        {
            $TODO ? ( todo => $TODO ) : (),
            %proto,
            pass => $pass ? 1 : 0,
            workflow => $workflow || undef,
#            Workflow->has_current
#                ? ( test => Workflow->current->test || undef )
#                : (),
        },
        $class
    );
}

for my $workflow_accessor ( @WORKFLOW_ACCESSORS ) {
    no strict 'refs';
    *$workflow_accessor = sub {
        my $self = shift;
        return $self->{ $workflow_accessor }
            if $self->{ $workflow_accessor };

        return undef unless $self->workflow
                        and $self->workflow->can( $workflow_accessor );

        return $self->workflow->$workflow_accessor;
    };
}

for my $any_accessor ( @WORKFLOW_OR_TEST_ACCESSORS ) {
    no strict 'refs';
    *$any_accessor = sub {
        my $self = shift;
        return $self->{ $any_accessor }
            if $self->{ $any_accessor };

        return $self->workflow->$any_accessor
            if $self->workflow && $self->workflow->can( $any_accessor );

        return $self->test->$any_accessor
            if $self->test && $self->test->can( $any_accessor );
    };
}

sub test {
    my $self = shift;
    if ( my $workflow = $self->workflow ) {
        return $workflow if $workflow->isa( 'Fennec::Test' );
        my $test = $workflow->test if $workflow->can( 'test' );
        return $test if $test;
    }
    return $self->{ test };
}

sub fail_workflow {
    my $class = shift;
    my ( $workflow, @stdout ) = @_;
    $class->new( 0, $workflow, stdout => \@stdout )->write;
}

sub skip_workflow {
    my $class = shift;
    my ( $workflow, $reason, @stdout ) = @_;
    $reason ||= $workflow->skip if $workflow->can( 'skip' );
    $reason ||= "no reason";
    $class->new( 0, $workflow, skip => $reason, stdout => \@stdout )->write;
}

sub pass_workflow {
    my $class = shift;
    my ( $workflow, @stdout ) = @_;
    $class->new( 1, $workflow, stdout => \@stdout )->write;
}

sub serialize {
    my $self = shift;
    my $data = { map {( $_ => ( $self->$_ || undef ))} @PROPERTIES };
    return {
        bless => ref( $self ),
        data => $data,
    };
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
