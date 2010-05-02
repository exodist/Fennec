package Fennec::Util::Accessors;
use strict;
use warnings;

use Carp;
use Scalar::Util qw/blessed/;

sub import {
    my $class = shift;
    my $caller = caller;
    no strict 'refs';
    *{ $caller . '::Accessors' } = sub {
        $class->build_accessors( $caller, @_ )
    };
}

sub alias {
    my $class = shift;
    my ($caller) = @{ shift(@_) };
    $class->build_accessors( $caller, @_ );
}

sub build_accessors {
    my $class = shift;
    my ( $caller, @list ) = @_;
    for my $accessor ( @list ) {
        my $sub = sub {
            my $self = shift;
            ($self->{ $accessor }) = @_ if @_;
            return $self->{ $accessor };
        };
        no strict 'refs';
        *{ $caller . '::' . $accessor } = $sub;
    }

}

1;

=head1 NAME

Fennec::Util::Accessors - Quick and dirty read-write accessor generator

=head1 DESCRIPTION

Provides a function that lets you quickyl generate basic read-write accessors.
Assumes your object is a blessed hash.

=head1 SYNOPSIS

    package MyPackage;
    use Fennec::Util::Accessors;
    Accessors qw/ thing stuff foo bar /;

    ...

    1;

=head1 EXPORTS

=over 4

=item Accessors( @list )

Add basic read/write accessors to the calling class. Each item in @list will be
assumed to be the name of the accessor.

=back

=head1 API (CLASS METHODS)

=over 4

=item build_accessors( $package, @list )

Adds accessors in list() to $package.

=item import()

Imports 'Accessors' into the callers namespace.

=item alias()

Used by L<Fennec::Util::Alias> so that when using this package aliased the
Accessors function behaves properly.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
