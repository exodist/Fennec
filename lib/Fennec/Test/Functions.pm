package Fennec::Test::Functions;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Group;
use Carp;

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
        my $gclass = $group =~ m/^Fennec::Group::/
            ? $group
            : 'Fennec::Group::' . $group;

        eval "require $gclass" || die ( $@ );
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

    my $sub = sub {
        my $name = shift;
        my %proto = @_ > 1 ? @_ : (method => shift( @_ ));
        my ( $caller, $file, $line ) = caller;
        Group->add_item( $gclass->new( $name, file => $file, line => $line, %proto ))
    };

    return $sub unless $specs and keys %$specs;

    return sub(&;@) {
        my ( $caller, $file, $line ) = caller;
        $sub->( "anonymous($gclass)", file => $file, line => $line, @_ )
    } if $specs->{ subproto };

    croak( "Unknown spec" );
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
