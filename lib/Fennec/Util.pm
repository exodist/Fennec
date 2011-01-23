package Fennec::Util;
use strict;
use warnings;
use Exporter::Declare;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;

exports qw/inject_sub accessors get_test_call/;

sub inject_sub {
    my ( $package, $name, $code ) = @_;
    croak "inject_sub() takes a package, a name, and a coderef"
        unless $package
            && $name
            && $code
            && $code =~ /CODE/;

    no strict 'refs';
    *{"$package\::$name"} = $code;
}

sub accessors {
    my $caller = caller;
    _accessor( $caller, $_ ) for @_;
}

sub _accessor {
    my ( $caller, $attribute ) = @_;
    inject_sub( $caller, $attribute, sub {
        my $self = shift;
        croak "$attribute() called on '$self' instead of an instance"
            unless blessed( $self );
        ( $self->{$attribute} ) = @_ if @_;
        return $self->{$attribute};
    });
}

sub get_test_call {
    my $runner;
    my $i = 1;

    while ( my @call = caller( $i++ )) {
        $runner = \@call if !$runner && $call[0]->isa('Fennec::Runner');
        return @call if $call[0]->can('FENNEC');
    }

    return( @$runner );
}

1;
