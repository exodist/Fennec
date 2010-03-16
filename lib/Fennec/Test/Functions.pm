package Fennec::Test::Functions;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Group;

Accessors qw/ groups functions /;

sub new {
    my $class = shift;
    my @groups = @_;
    my $self = bless({ groups => \@groups }, $class );
    $self->build;
    return $self;
}

sub build {
    my $self = shift;
    my $groups = $self->groups;
    my %functions;
    while( my $group = pop @$groups ) {
        my $gclass = $group =~ m/^Fennec::Group/
            ? $group
            : 'Fennec::Group::' . $gclass;

        next if $functions{ $gclass };
        push @$groups => @{ $gclass->depends };
        my ( $function, %specs ) = $gclass->function;
        $functions{ $gclass } = [ $function, \%specs ];
    }
    $self->functions( \%functions );
}

sub export_to {
    my $self = shift;
    my ( $dest ) = @_;
    my $functions = $self->functions;
    for my $gclass ( keys %$functions ) {
        my $sub = $self->sub_for( $gclass );
        no strict 'refs';
        *{ $dest . '::' . $functions->{ $gclass }->[0]} = $sub;
    }
}

sub sub_for {
    my $self = shift;
    my ( $gclass ) = @_;
    my ( $function, $specs ) = @{ $self->functions->{ $gclass }};
    my $sub = sub { Group->add_item( $gclass->new( @_ ))};
    return $sub unless $specs and keys %$specs;
    return sub(&;@) { $sub->( "anonymous($gclass)", @_ ) } if $specs->{ subproto };
    croak( "Unknown spec" );
}

1;
