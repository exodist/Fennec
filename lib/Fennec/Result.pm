package Fennec::Result;
use strict;
use warnings;
use Carp;

our @REQUIRED = qw/result name time case set file line/;
our @ALT_REQUIRED = qw/diag/;
our @CARP_NOT = qw/Fennec::Tester/;

sub new {
    my $class = shift;
    my $proto = @_ > 1 ? {@_} : $_[0];

    my $is_diag = ( exists $proto->{ diag } && !exists $proto->{ result }) ? 1 : 0;
    my @need = grep { !exists $proto->{$_} } @REQUIRED unless $is_diag;

    confess(
        "Result did not have all necessary params, missing: "
        . join( ", ", @need )
        . " use undef if param is really unavailable"
    ) if ( @need && !$is_diag );

    return bless(
        {
            %$proto,
            is_diag => $is_diag,
        },
        $class
    );
}

for my $reader (qw/result name case set time diag is_diag file line/) {
    my $sub = sub {
        my $self = shift;
        return $self->{ $reader };
    };
    no strict 'refs';
    *$reader = $sub;
}

sub todo {
    my $self = shift;
    return $self->_self_set_or_case( 'todo' );
}

sub skip {
    my $self = shift;
    return $self->_self_set_or_case( 'skip' );
}

sub _self_set_or_case {
    my $self = shift;
    my ($thing) = @_;

    return $self->{ $thing }
        if $self->{ $thing };

    my $case = $self->case;
    return unless $case;

    my $set = $self->set;
    return $case->$thing unless $set;

    return $set->$thing || $case->$thing;
}

1;
