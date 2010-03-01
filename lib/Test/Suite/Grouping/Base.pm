package Test::Suite::Grouping::Base;
use strict;
use warnings;
use Carp;
our @CARP_NOT = ( __PACKAGE__, qw/Test::Suite::Grouping Test::Suite Test::Suite::Plugin/ );
use Scalar::Util qw/blessed/;

sub new {
    my $class = shift;
    my ( $name, %proto ) = @_;
    croak( "No method provided" )
        unless $proto{method};
    return bless({%proto, name => $name}, $class );
}

sub name {
    my $self = shift;
    return $self->{ name };
}

sub method {
    my $self = shift;
    return $self->{ method };
}

sub type { 'Base' }

sub run {
    my $self = shift;
    my ( $test ) = @_;
    my $method = $self->method;
    croak(
        $self->type . " '" . $self->name . "': test '"
        . blessed( $test ) . "' does not have a method named '$method'"
    ) unless ( ref( $method ) || $test->can( $method ));
    $test->$method();
}

1;
