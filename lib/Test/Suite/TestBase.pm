package Test::Suite::TestBase;
use strict;
use warnings;
use Carp;
use Try::Tiny;
use List::Util qw/shuffle/;
use Scalar::Util qw/blessed/;
use Test::Suite::Grouping::Case;
use Test::Suite::Grouping::Set;

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
    $self->_cases->{ $name } = Test::Suite::Grouping::Case->new( $name, %{ $self->case_defaults }, %proto );
}

sub add_set {
    my ( $class, $self ) = _get_self( @_ );
    my ( $name, %proto ) = @_;
    croak( "Set with name $name already exists" )
        if $self->_sets->{ $name };
    $self->_sets->{ $name } = Test::Suite::Grouping::Set->new( $name, %{ $self->case_defaults }, %proto );
}

sub cases {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my ( $random ) = @_;
    my $cases = $self->_cases;
    my @list = values %$cases;

    # 'DEFAULT' case
    push @list => Test::Suite::Grouping::Case->new( 'DEFAULT', %{ $self->case_defaults }, method => sub {1} )
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
        # TODO: If parrallel then fork before running the case
        #       If force_fork then fork but wait before continuing (unless parallel)
        #       If no_fork, but in parrallel, then store case/set pair for later.
        $self->case( $case );
        $case->run( $self );

        for my $set ( $self->sets( $self->random )) {
            # TODO: If parrallel then fork before running the set
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
