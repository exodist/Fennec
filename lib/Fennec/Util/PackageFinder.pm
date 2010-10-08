package Fennec::Util::PackageFinder;
use strict;
use warnings;

use Fennec::Exporter::Declare;
use Carp;

export 'load_package';

sub load_package {
    my ($name, $namespace) = @_;
    $namespace ||= "";

    my @options = ( $name );
    push @options => "$namespace\::$name" if $namespace;

    @options = reverse @options
        if $name =~ m/::/;

    for my $pkg ( @options ) {
        return $pkg if eval "require $pkg; 1";
        my $file = $pkg;
        $file =~ s|::|/|g;
        croak( $@ ) unless $@ =~ m{Can't locate /?$file\.pm in \@INC};
    }
    croak( "Could not find $name as " . join( ' or ', @options ));
}

1;

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
