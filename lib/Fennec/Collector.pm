package Fennec::Collector;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Util::Abstract;

Accessors qw/handlers/;
Abstract  qw/cull write/;

sub new {
    my $class = shift;
    my @handlers;
    for my $hclass ( @_ ) {
        $hclass = 'Fennec::Handler::' . $hclass;
        eval "require $hclass; 1" || die ( @_ );
        push @handlers => $hclass->new();
    }
    my $self = bless( { handlers => \@handlers }, $class );
    $self->init if $self->can( 'init' );
    return $self;
}

sub start {
    my $self = shift;
    $_->start for @{ $self->handlers };
}

sub finish {
    my $self = shift;
    $self->cull;
    $_->finish for @{ $self->handlers };
}

1;
