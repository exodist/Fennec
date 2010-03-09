package Fennec::Result;
use strict;
use warnings;
use Carp;

our @REQUIRED = qw/result name benchmark case set file line test/;
use Fennec::Util qw/add_accessors/;
use Scalar::Util qw/blessed/;

use Data::Dumper;

add_accessors qw/result name case set diag is_diag file line benchmark test/;

sub new {
    my $class = shift;
    my $proto = @_ > 1 ? {@_} : $_[0];

    my $is_diag = $proto->{ is_diag } || ( exists $proto->{ diag } && !exists $proto->{ result }) ? 1 : 0;
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

sub deserialize {
    my $class = shift;
    my ( $data ) = @_;
    chomp( $data );
    my $VAR1;
    my $proto = eval $data || die( "Deserialization error $@" );
    if ( $proto->{ test } ) {
        $proto->{ test } = Fennec::Runner->get->get_test( delete $proto->{ test_class }) || undef;
        $proto->{ case } = $proto->{ test }->_cases->{ delete $proto->{ case_name }} || undef;
        $proto->{ set } = $proto->{ test }->_sets->{ delete $proto->{ set_name }} || undef;
    }
    else {
        $proto->{ test } = undef;
        $proto->{ case } = undef;
        $proto->{ set }  = undef;
    }
    delete $proto->{ todo } unless $proto->{ todo };
    delete $proto->{ skip } unless $proto->{ skip };
    return $class->new( $proto );
}

sub serialize {
    my $self = shift;
    my $data = { map { $_ => $self->$_ } qw/result name benchmark file line diag is_diag todo skip/};
    $data->{ test_class } = blessed( $self->test ) if $self->test;
    $data->{ case_name } = $self->case->name if $self->case;
    $data->{ set_name } = $self->set->name if $self->set;
    local $Data::Dumper::Indent = 0;
    return Dumper( $data );
}

sub todo {
    my $self = shift;
    return $self->_self_case_or_set( 'todo' );
}

sub skip {
    my $self = shift;
    return $self->_self_case_or_set( 'skip' );
}

sub _self_case_or_set {
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
