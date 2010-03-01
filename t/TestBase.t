#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;

my $CLASS = 'Test::Suite::TestBase';
use_ok( $CLASS );

throws_ok { my $one = $CLASS->new() }
          qr/$CLASS cannot not be instantiated/,
          "Cannot init base class";

{
    package My::Test;
    use strict;
    use warnings;
    use base 'Test::Suite::TestBase';
}

$CLASS = 'My::Test';

ok(
    my $one = $CLASS->new(
        random => 1,
        parallel => 1,
        case_defaults => {},
        set_defaults => {},
        filename => 1,
    ),
    "New instance"
);
isa_ok( $one, 'Test::Suite::TestBase' );
isa_ok( $one, $CLASS );
is( $one, $CLASS->new, "singleton" );

is( $one->random, 1, "random()" );
is( $one->parallel, 1, "parallel()" );
is( $one->filename, 1, "filename()" );
is_deeply( $one->case_defaults, {}, "case_defaults" );
is_deeply( $one->set_defaults, {}, "set_defaults" );
is_deeply( $one->_cases, {}, "_cases" );
is_deeply( $one->_sets, {}, "_sets" );
ok( $one->_cases != $one->_cases({}), "Accessors" );
ok( $one->random(5) != 5, "Readers" );
can_ok( $one, 'set', 'case', '__find_subs' );

{
    no warnings 'redefine';
    *Test::Suite::Grouping::Case::new = sub { \@_ };
    *Test::Suite::Grouping::Set::new = sub { \@_ };
}



done_testing;

__END__

sub add_case {
    my ( $class, $self ) = _get_self( @_ );
    my ( $name, %proto ) = @_;
    croak( "Case with name $name already exists" )
        if $self->_cases->{ $name };
    $self->_cases->{ $name } = Test::Suite::Grouping::Case->new( $name, %proto );
}

sub add_set {
    my ( $class, $self ) = _get_self( @_ );
    my ( $name, %proto ) = @_;
    croak( "Set with name $name already exists" )
        if $self->_sets->{ $name };
    $self->_sets->{ $name } = Test::Suite::Grouping::Set->new( $name, %proto );
}

sub cases {
    my ( $class, $self ) = _get_self( @_ );
    $self->_find_subs;
    my ( $random ) = @_;
    my $cases = $self->_cases;
    my @list = values %$cases;
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
        $self->case( $case );
        $case->run( $self );

        for my $set ( $self->sets( $self->random )) {
            $self->set( $set );

            $set->run( $self );

            $self->set( undef );
        }

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
    for my $sub ( @subs ) {
        next unless m/^(set|case)_(.*)$/;
        my $add = "add_$1";
        $self->$add( $2, method => $2 );
    }
}

1;
