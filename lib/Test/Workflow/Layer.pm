package Test::Workflow::Layer;
use strict;
use warnings;

use Test::Workflow::Block;

use Fennec::Util qw/accessors/;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

our @ATTRIBUTES = qw/
    test
    case
    child
    before_each
    before_all
    after_each
    after_all
    around_each
    around_all
/;

accessors 'finalized', @ATTRIBUTES;

sub new { bless({ map {( $_ => [] )} @ATTRIBUTES }, shift )}

sub clone {
    my $self = shift;
    my $class = blessed( $self );
    my $new = bless( { %{$self} }, $class );
    return $new;
}

sub merge_in {
    my $self = shift;
    my ( $caller, @classes ) = @_;
    for my $class ( @classes ) {
        eval "require $class; 1" || die $@;
        push @{ $self->$_ } => @{ $class->TEST_WORKFLOW->root_layer->$_ } for @ATTRIBUTES;
    }
}

for my $type ( qw/test case child before_each before_all around_each around_all/ ) {
    my $add = sub {
        my $self = shift;
        push @{ $self->$type } => Test::Workflow::Block->new( @_ );
    };
    no strict 'refs';
    *{"add_$type"} = $add;
}

for my $type ( qw/after_each after_all/ ) {
    my $add = sub {
        my $self = shift;
        unshift @{ $self->$type } => Test::Workflow::Block->new( @_ );
    };
    no strict 'refs';
    *{"add_$type"} = $add;
}

sub get_all {
    my $self = shift;
    my ( $type ) = @_;
    return @{ $self->$type }
        if $self->can( $type );

    croak "No such type: $type";
}

1;

__END__

=head1 NAME

Test::Workflow::Layer - Used to track per-encapsulation meta-data

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Test-Workflow is free software; Standard perl licence.

Test-Workflow is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
