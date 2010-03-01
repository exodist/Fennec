package Fennec::TestBase;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Fennec::TestBase - Base class for Test classes.

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

#}}}

use Carp;
use Try::Tiny;
use List::Util qw/shuffle/;
use Scalar::Util qw/blessed/;
use Fennec::Grouping::Case;
use Fennec::Grouping::Set;

our %SINGLETONS;
sub _get_self(\@);

sub new {
    my $class = shift;
    croak( "$class cannot not be instantiated" )
        if $class eq __PACKAGE__;
    my %proto = @_;
    $SINGLETONS{$class} ||= bless(
        {
            case_defaults => {},
            set_defaults => {},
            %proto,
            _cases => {},
            _sets => {}
        },
        $class
    );
    return $SINGLETONS{$class};
}

for my $reader (qw/filename parallel random case_defaults set_defaults/) {
    my $sub = sub {
        my ( $class, $self ) = _get_self( @_ );
        return $self->{ $reader };
    };
    no strict 'refs';
    *$reader = $sub;
}

for my $accessor (qw/set case _cases _sets __find_subs/) {
    my $sub = sub {
        my ( $class, $self ) = _get_self( @_ );
        ($self->{ $accessor }) = @_ if @_;
        return $self->{ $accessor };
    };
    no strict 'refs';
    *$accessor = $sub;
}

sub add_case {
    my ( $class, $self ) = _get_self( @_ );
    my ( $name, %proto ) = @_;
    croak( "Case with name $name already exists" )
        if $self->_cases->{ $name };
    $self->_cases->{ $name } = Fennec::Grouping::Case->new( $name, %{ $self->case_defaults }, %proto );
}

sub add_set {
    my ( $class, $self ) = _get_self( @_ );
    my ( $name, %proto ) = @_;
    croak( "Set with name $name already exists" )
        if $self->_sets->{ $name };
    $self->_sets->{ $name } = Fennec::Grouping::Set->new( $name, %{ $self->case_defaults }, %proto );
}

sub cases {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my ( $random ) = @_;
    my $cases = $self->_cases;
    my @list = values %$cases;

    # 'DEFAULT' case
    push @list => Fennec::Grouping::Case->new( 'DEFAULT', %{ $self->case_defaults }, method => sub {1} )
        unless @list;
    return $random ? (shuffle @list) : (sort { $a->name cmp $b->name } @list);
}

sub sets {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my ( $random ) = @_;
    my $sets = $self->_sets;
    my @list = values %$sets;
    return $random ? (shuffle @list) : (sort { $a->name cmp $b->name } @list);
}

sub run {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my $init = $self->can( 'initialize' ) || $self->can( 'init' );
    $self->$init if $init;

    for my $case ( $self->cases( $self->random )) {
        # TODO: If parallel then fork before running the case
        #       If force_fork then fork but wait before continuing (unless parallel)
        #       If no_fork, but in parallel, then store case/set pair for later.
        $self->case( $case );
        $case->run( $self );

        for my $set ( $self->sets( $self->random )) {
            # TODO: If parallel then fork before running the set
            #       See rules for CASE above.
            $self->set( $set );

            $set->run( $self );

            #TODO report status of set.
            $self->set( undef );
        }

        #TODO report status of case.
        $self->case( undef );
    }
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

    my @subs;
    {
        my $us = $class . '::';
        no strict 'refs';
        @subs = grep { defined( *{$us . $_}{CODE} )}
                  keys %$us;
    }
    for ( @subs ) {
        next unless m/^(set|case)_(.*)$/i;
        my ( $name, $type ) = ( $2, lc($1));
        my $add = "add_$type";
        $self->$add( $name, method => $_ );
    }
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
