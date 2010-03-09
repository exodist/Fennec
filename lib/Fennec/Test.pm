package Fennec::Test;
use strict;
use warnings;

use Carp;
use Try::Tiny;
use List::Util qw/shuffle sum/;
use Scalar::Util qw/blessed/;
use Fennec::Group::Case;
use Fennec::Group::Set;
use Time::HiRes;
use Benchmark qw/timeit :hireswallclock/;
use Fennec::Util qw/add_accessors get_all_subs/;

our %SINGLETONS;
sub _get_self(\@);

add_accessors qw/filename parallel case_defaults set_defaults todo set
                 case _cases _sets __find_subs/;

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
            random => 1,
            %proto,
        },
        $class
    );

    return $SINGLETONS{$class};
}

sub random {
    my $self = shift;
    return 0 unless $self->{ random };
    return 0 unless Fennec::Runner->get->random;
    return 1;
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

sub cases {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my $cases = $self->_cases;
    my @list = values %$cases;

    # 'DEFAULT' case
    push @list => Fennec::Group::Case->new( 'DEFAULT', test => $self, %{ $self->case_defaults }, method => sub {1} )
        unless @list;
    return @list;
}

sub sets {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my $sets = $self->_sets;
    return values %$sets;
}

sub run {
    my ( $class, $self ) = _get_self( @_ );
    my ( $case_name, $set_name ) = @_;
    $self->_find_subs;
    my $init = $self->can( 'initialize' ) || $self->can( 'init' );
    $self->$init if $init;

    my $data = $self->_organize;
    my @partitions = values %$data;
    @partitions = shuffle( @partitions ) if $self->random;

    for my $partition ( @partitions ) {
        Fennec::Runner->get->threader->thread( 'partition', sub {
            my @cases = @{ $partition->{ cases }};
            my @sets = @{ $partition->{ sets }};
            @cases = shuffle( @cases ) if $self->random;
            for my $case ( @cases ) {
                next if $case_name and $case_name ne $case->name;
                Fennec::Runner->get->threader->thread( 'case', sub {
                    $self->_run_case( $case, $set_name, @sets );
                });
            }
        });
    }
}

sub specs {
    my ( $class, $self ) = _get_self( @_ );
    my %specs = (
        sets => ($self->sets),
        cases => ($self->cases),
        partitions => (keys %{$self->_organize}),
        # This is how many times this test will run a set
        # p1cases * p1sets + p2cases * p2sets ...
        runs => sum( map { @{$_->{cases}} * @{$_->{sets}} } values %{$self->_organize}),
    );
}

sub _organize {
    my ( $class, $self ) = _get_self( @_ );
    unless ( $self->{ _organize }) {
        my %out;
        for my $item ( sort { $a->name cmp $b->name } $self->cases, $self->sets ) {
            my $type = lc($item->type) . 's';
            for my $part (@{ $item->partition }) {
                $out{ $part } ||= { cases => [], sets => []};
                push @{ $out{$part}{$type}} => $item;
            }
        }
        $self->{ _organize } = \%out;
    }
    $self->{ _organize };
}

sub _run_case {
    my $self = shift;
    my ( $case, $set_name, @sets ) = @_;
    croak( "Already running a case" )
        if $self->case;

    Fennec::Runner->get->diag( "Running case: " . $case->name );
    $self->case( $case );
    my ( $cr, @cd );
    my $benchmark = timeit( 1, sub {
        ( $cr, @cd ) = $case->skip
            ? ( 1, $case->skip )
            : try {
                $case->run( $self );

                @sets = shuffle( @sets ) if $case->random;
                for my $set ( @sets ) {
                    next if $set_name and $set_name ne $set->name;
                    Fennec::Runner->get->threader->thread( 'set', sub {
                        $self->_run_set( $set );
                    });
                }

                return ( 1 );
            }
            catch { return ( 0, $_ )};
    });

    $self->_result( $cr, "End of case - " . $case->name, $benchmark, \@cd );
    $self->case( undef );
}

sub _run_set {
    my $self = shift;
    my ( $set ) = @_;
    croak( "Already running a set" )
        if $self->set;

    Fennec::Runner->get->diag( "Running set: " . $set->name );
    $self->set( $set );
    my ( $sr, @sd );
    my $benchmark = timeit( 1, sub {
        ( $sr, @sd ) = $set->skip
            ? ( 1, $set->skip )
            : try {
                my $out = $set->run( $self );
                return $out ? ($out) : (0, "One or more tests failed.");
            } catch { return (0, $_ )};
    });

    $self->_result( $sr, "End of set - " . $set->name, $benchmark, \@sd );
    $self->set( undef );
    return 1 if $set->todo;
    return $sr;
}

sub _result {
    my $self = shift;
    my ( $ok, $name, $benchmark, $diag ) = @_;

    my $case = $self->case || undef;
    my $set = $self->set || undef;

    my $result = Fennec::Result->new(
        result => $ok,
        name   => $name,
        diag   => $diag,
        case   => $case,
        set    => $set,
        test   => $self,
        line   => $case ? $set ? $set->line : $case->line : undef,
        file   => $case ? $set ? $set->filename : $case->filename : $self->filename,
        benchmark   => $benchmark,
    );
    Fennec::Runner->get->result( $result );
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

sub _find_subs {
    my ( $class, $self ) = _get_self( @_ );
    return if $self->__find_subs;
    $self->__find_subs(1);

    for ( get_all_subs( $class )) {
        next unless m/^(set|case)_(.*)$/i;
        my ( $name, $type ) = ( $2, lc($1));
        my $add = "add_$type";
        $self->$add( $name, method => $_, test => $class );
    }
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
