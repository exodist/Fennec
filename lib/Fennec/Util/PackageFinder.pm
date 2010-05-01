package Fennec::Util::PackageFinder;
use strict;
use warnings;

use Exporter::Declare;
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
