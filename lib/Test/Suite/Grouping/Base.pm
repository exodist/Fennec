package Test::Suite::Grouping::Base;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Test::Suite::Grouping::Base - Base class for grouping classes

=head1 DESCRIPTION

Sets and Cases use this as a base class.

=head1 EARLY VERSION WARNING

This is VERY early version. Test::Suite does not run yet.

Please go to L<http://github.com/exodist/Test-Suite> to see the latest and
greatest.

=head1 METHODS

=over 4

=cut

#}}}

use Carp;
our @CARP_NOT = ( __PACKAGE__, qw/Test::Suite::Grouping Test::Suite Test::Suite::Plugin/ );
use Scalar::Util qw/blessed/;

=item $class->new( $name, %proto )

Create a new instance

=cut

sub new {
    my $class = shift;
    my ( $name, %proto ) = @_;
    croak( "No method provided" )
        unless $proto{method};
    return bless({%proto, name => $name}, $class );
}

=item $name = $obj->name()

Returns the name of the object

=cut

sub name {
    my $self = shift;
    return $self->{ name };
}

=item $method = $obj->method()

Returns the method associated with the object. Can be a coderef or method name.

=cut

sub method {
    my $self = shift;
    return $self->{ method };
}

=item $type = $obj->type()

Get the type of object. Subclasses should override this.

=cut

sub type { 'Base' }

=item $obj->run( $test )

Run the object method on the the specified test object.

=cut

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

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
