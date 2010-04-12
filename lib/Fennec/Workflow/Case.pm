package Fennec::Workflow::Case;
use strict;
use warnings;

use Fennec::Workflow qw/:subclass/;

use Fennec::Util::Alias qw/
    Fennec::Workflow
    Fennec::TestSet
    Fennec::TestSet::SubSet
    Fennec::TestSet::SubSet::Setup
    Fennec::Runner
    Fennec::Util::Accessors
/;

Accessors qw/ cases /;

sub init {
    my $self = shift;
    $self->$_([]) for qw/ cases /;
}

export cases => sub {
    Fennec::Workflow->current->add_item(
        __PACKAGE__->new( @_ )
    );
};

export case => sub {
    Fennec::Workflow->current->add_item(
        Setup->new( @_ )
    );
};

sub testsets {
    my $self = shift;
    my @sets = @{ $self->_testsets };
    my @cases = @{ $self->cases };
    my @out;

    for my $case ( @cases ) {
        for my $test ( @sets ) {
            my $subset = SubSet->new(
                name => $case->name . " x " . $test->name,
                workflow => $self,
                file => $self->file,
            );
            push @{ $subset->{tests} } => $test;
            $subset->setups([ $case ]);
            push @out => $subset;
        }
    }

    return @out;
}

sub add_setup {
    my $self = shift;
    my ( $setup ) = @_;
    push @{ $self->cases } => $setup;
}

sub add_item {
    my $self = shift;
    my ( $item ) = @_;

    return $self->add_setup( $item )
        if $item->isa( Setup() );

    return $self->SUPER::add_item( $item );
}

1;
