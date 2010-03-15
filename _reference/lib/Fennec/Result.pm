package Fennec::Result;
use strict;
use warnings;
use Carp;

our @REQUIRED = qw/result name benchmark stacknode file line test group tests/;
use Fennec::Util qw/add_accessors/;
use Scalar::Util qw/blessed/;
use Dennec::Runner;
use Data::Dumper;

add_accessors qw/result name stacknode diag is_diag file line benchmark test
                 group tests/;

sub skip_item {
    my $class = shift;
    my ( $item, $node, $skip ) = @_;
    $skip ||= $item->skip || "no reason";
    return $class->new(
        result      => 0,
        name        => $item->name
        stacknode   => $node,
        skip        => $skip,
        file        => $item->filename,
        line        => $item->line,
        test        => $item->test,
        group       => $item,
        tests       => undef,
    );
}

sub fail_item {
    my $class = shift;
    my ( $item, $node, $diag ) = @_;
    return $class->new(
        result      => 0,
        name        => $item->name
        stacknode   => $node,
        diag        => $diag || undef,
        file        => $item->filename,
        line        => $item->line,
        test        => $item->test,
        group       => $item,
        tests       => undef,
    );
}

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
    if ( $proto->{ test_class } ) {
        $proto->{ test } = Runner->get->get_test( delete $proto->{ test_class }) || undef;
    }
    else {
        $proto->{ test } = undef;
    }
    delete $proto->{ todo } unless $proto->{ todo };
    delete $proto->{ skip } unless $proto->{ skip };
    return $class->new( $proto );
}

sub serialize {
    my $self = shift;
    my $data = { map { $_ => $self->$_ } qw/result name benchmark file line diag is_diag todo skip/};
    $data->{ test_class } = blessed( $self->test ) if $self->test;
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
