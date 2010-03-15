package Fennec::Test;
use strict;
use warnings;

use Carp;
use Try::Tiny;
use List::Util qw/shuffle sum/;
use Scalar::Util qw/blessed/;
use Fennec::Groups::Case;
use Fennec::Groups::Set;
use Time::HiRes;
use Benchmark qw/timeit :hireswallclock/;
use Fennec::Util qw/add_accessors get_all_subs/;

our %SINGLETONS;
sub _get_self(\@);

add_accessors qw/filename parallel case_defaults set_defaults todo
                 _cases _sets _specs __find_subs _spec_stack/;

sub get { goto @new }

sub new {
    my $class = shift;
    croak( "$class cannot not be instantiated" )
        if $class eq __PACKAGE__;
    my %proto = @_;
    $SINGLETONS{$class} ||= bless(
        {
            case_defaults => {},
            set_defaults => {},
            _cases => {},
            _sets => {},
            _specs => {},
            _spec_stack => [];
            random => 1,
            %proto,
        },
        $class
    );

    return $SINGLETONS{$class};
}

#{{{ stack methods

sub _stack_push {

}

sub _stack_pop {

}

sub _stack_peek {

}

#}}}

sub random {
    my ( $class, $self ) = _get_self( @_ );
    return 0 unless $self->{ random };
    return 0 unless Fennec::Runner->get->random;
    return 1;
}

sub add_spec {

}

sub add_case {
    my ( $class, $self ) = _get_self( @_ );
    my ( $name, %proto ) = @_;
    croak( "Case with name $name already exists" )
        if $self->_cases->{ $name };
    $self->_cases->{ $name } = Fennec::Group::Case->new( $name, test => $self, %{ $self->case_defaults }, %proto );
}

sub add_set {
    my ( $class, $self ) = _get_self( @_ );
    my ( $name, %proto ) = @_;
    croak( "Set with name $name already exists" )
        if $self->_sets->{ $name };
    $self->_sets->{ $name } = Fennec::Group::Set->new( $name, test => $self, %{ $self->case_defaults }, %proto );
}

sub specs {

}

sub cases {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my $cases = $self->_cases;
    my @list = values %$cases;

    # 'DEFAULT' case
    push @list => Fennec::Group::Case->new( 'DEFAULT', test => $self, %{ $self->case_defaults }, method => sub {1} )
        if $self->sets && !@list;

    return @list;
}

sub sets {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my $sets = $self->_sets;
    return values %$sets;
}

sub scenario_map {
    my ( $class, $self ) = _get_self( @_ );
    my %scen = (
        sets => ($self->sets),
        cases => ($self->cases),
        partitions => (keys %{$self->scenarios}),
        describes => 0,
        its => 0,
        # This is how many times this test will run a set
        # p1cases * p1sets + p2cases * p2sets ...
        # Add in it1 * descs_run_under + ...
        runs => sum( map { @{$_->{cases}} * @{$_->{sets}} } values %{$self->scenarios}),
    );
}

sub scenarios {
    my ( $class, $self ) = _get_self( @_ );
    unless ( $self->{ scenarios }) {
        my %out;
        for my $item ( sort { $a->name cmp $b->name } $self->cases, $self->sets ) {
            my $type = lc($item->type) . 's';
            for my $part (@{ $item->partition }) {
                $out{ $part } ||= { cases => [], sets => []};
                push @{ $out{$part}{$type}} => $item;
            }
        }
        $self->{ scenarios } = \%out;
    }
    $self->{ scenarios };
}


sub _get_self(\@) {
    my $in = eval { shift(@{$_[0]}) } || confess($@);
    my $class = blessed( $in ) || $in;
    croak( "No class or object specified" )
        unless( $class );

    my $self = $SINGLETONS{$class};
    croak( "Could not find singleton for class '$class'" )
        unless $self;

    return ($class, $self);
}

1;

=pod

=head1 NAME

Fennec::Test - Base class for Test classes.

=head1 DESCRIPTION

This class is the base class for test classes users define.

=head1 SYNOPSYS

    package My::Test;
    use Fennec;

This is all you need to make a test class using this as a base.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=cut

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
