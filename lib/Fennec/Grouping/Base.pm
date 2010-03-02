package Fennec::Grouping::Base;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Fennec::Grouping::Base - Base class for grouping classes

=head1 DESCRIPTION

Sets and Cases use this as a base class.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 METHODS

=over 4

=cut

#}}}

use Carp;
our @CARP_NOT = ( __PACKAGE__, qw/Fennec::Grouping Fennec Fennec::Plugin/ );
use Scalar::Util qw/blessed/;
use Sub::Information as => 'inspect';

=item $class->new( $name, %proto )

Create a new instance

=cut

sub new {
    my $class = shift;
    my ( $name, %proto ) = @_;

    my $method = $proto{method};
    my $ref = ref( $method ) ? $method
                             : $proto{test}->can( $method );

    croak(
        $method ? "$method is not a valid method for $class"
                : "No method provided"
    ) unless $ref;

    my $info = inspect( $ref );

    return bless(
        {
            %proto,
            name => $name,
            filename => $info->file,
            line => $info->line,
        },
        $class
    );
}

sub todo {
    my $self = shift;
    return $self->{ todo };
}

sub test {
    my $self = shift;
    return $self->{ test };
}

sub filename {
    my $self = shift;
    return $self->{ filename };
}

sub line {
    my $self = shift;
    return $self->{ line };
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

=item $obj->run()

Run the object method.

=cut

sub run {
    my $self = shift;
    my $method = $self->method;
    $self->test->$method();
}

1;

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
