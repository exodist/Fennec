package Fennec::Meta::TestClass;
use strict;
use warnings;

use Fennec::Runner;
use Fennec::Util qw/array_accessors accessors/;

use base 'Fennec::Meta';

accessors qw/ parallel base /;
array_accessors qw/ stack /;

sub top { shift->stack_peek }

sub new {
    my $class = shift;
    my %proto = @_;
    my $self = bless({
        $proto{fennec}->defaults,
        %proto,
    }, $class );
    $self->stack_push( $self );

    Fennec::Runner->push_test_class( $self->class );
    if ( $self->base ) {
        no strict 'refs';
        push @{$self->class . '::ISA'} => $self->base;
    }

    return $self;
}


1
