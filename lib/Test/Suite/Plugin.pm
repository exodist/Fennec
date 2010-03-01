package Test::Suite::Plugin;
use strict;
use warnings;
use Time::HiRes qw/time/;
use Carp;
use Scalar::Util 'blessed';
our @CARP_NOT = ( __PACKAGE__, 'Test::Suite::TestHelper' );

#{{{ POD

=pod

=head1 NAME

Test::Suite::Plugin - Used by plugins to turn them into plugins.

=head1 DESCRIPTION

All plugins must use this class to define their exported functionality.

=head1 EARLY VERSION WARNING

This is VERY early version. Test::Suite does not run yet.

Please go to L<http://github.com/exodist/Test-Suite> to see the latest and
greatest.

=head1 SYNOPSYS

To create a plugin create a module directly under the L<Test::Suite::Plugin>
namespace. Define testers and utilies.

    package Test::Suite::Plugin::MyPlugin;
    use strict;
    use references;
    use Test::Suite::Plugin;

    # define a util function
    util my_diag => sub { Test::Suite->diag( @_ ) };

    # define a tester
    tester my_ok => (
        min_args => 1,
        max_args => 2,
        code => sub {
            my ( $result, $name ) = @_;
            return ( $result ? 1 : 0, $name );
        },
    );

    # Define one with a prototype
    tester my_dies_ok => sub(&;$) {
        eval $_[0]->() || return ( 1, $_[1]);
        Test::Suite->diag( "Test did not die as expected" );
        return ( 0, $_[1] );
    };

    1;

=head1 WRAPPER PLUGINS

Plugins can be made to wrap around existing L<Test::Builder> based testing
utilities. This is how L<Test::More> and L<Test::Warn> functionality is
provided. Here is the Test::More wrapper plugin as an example.

    package Test::Suite::Plugin::More;
    use strict;
    use warnings;

    use Test::Suite::Plugin;

    our @SUBS;
    BEGIN {
        @SUBS = qw/ is isnt like unlike cmp_ok is_deeply can_ok isa_ok /;
    }

    use Test::More import => \@SUBS;

    tester $_ => $_ for @SUBS;
    util diag => sub { Test::Suite->diag( @_ ) };
    util todo => sub(&$) {
        my ( $code, $todo ) = @_;
        local $Test::Suite::Plugin::TODO = $todo;
        $code->();
    };

    1;

=head1 TESTING

TODO

=head1 ADVANCED TESTERS

TODO - talk about defining argument types

=cut

#}}}

#{{{ TYPES
our %TYPES = (
    Ref         => sub { ref( $_[0] ) ? 1 : 0},
    HashRef     => sub { _ref_is( @_, 'HASH' )},
    ArrayRef    => sub { _ref_is( @_, 'ARRAY' )},
    RegexpRef   => sub { _ref_is( @_, 'Regexp' )},
    CodeRef     => sub { _ref_is( @_, 'CODE' )},
    Str         => sub { ref( $_[0] ) ? 0 : 1},
    Int         => [ qr/^\d+$/, sub { ref $_[0] ? 0 : 1}],
    Any         => sub { 1 },
    Undef       => sub { !defined( $_[0] )},
    Num         => sub {
        my $val = shift;
        return 0 if ref $_[0];
        return 1 if $val =~ m/^\d+$/;
        return 1 if $val =~ m/^\d+\.\d*$/;
        return 1 if $val =~ m/^\d*\.\d+$/;
        return 0;
    },
);

for my $type ( keys %TYPES ) {
    no strict 'refs';
    *$type = sub { $TYPES{ $type }};
}
#}}}
our @EXPORT = (qw/export_to tester util todo no_test/, keys %TYPES);
our %SUBS;
our $TIMER;
our $NO_TEST = \"No Test";
our $TB_USED = 0;
our $TODO = "";

=head1 IMPORT

=cut

sub import {
    my $class = shift;
    my ( $arg ) = @_;
    return if $arg and $arg eq 'no_import';
    my ( $package ) = caller;

    no strict 'refs';
    push @{ $package . '::ISA' } => $class;
    *{ $package . '::' . $_ } = \&{ $_ } for @EXPORT;
}

=head1 CLASS METHODS

=over 4

=item my $reason = $class->todo()

If the tests are currently runnign under TODO this will returnt he reason,
otherwise it will return false.

=cut

sub todo { $TODO }

=item $class->export_to( $package )

Export testers and utils from the plugin to the specified package.

=cut

sub export_to {
    my $class = shift;
    my ( $package, $prefix ) = @_;
    return 1 unless $package;

    return unless my $subs = $SUBS{ $class };

    for my $name ( keys %$subs ) {
        my $newname = $prefix ? "$prefix$name" : $name;
        no strict 'refs';
        use Data::Dumper;
        print Dumper( $package . '::' . $newname, $subs->{ $name }, \$TODO ) if $name eq 'TODO';
        *{ $package . '::' . $newname } = $subs->{ $name };
    }
}

=back

=head1 EXPORTED FUNCTIONS

These functions are exported for use in your plugins.

=over 4

=item no_test()

If a tester sub returns the result of this function then no test will be
recorded. This can be used to abord a tester without any record.

=cut

sub no_test { return $NO_TEST }

=item util( $name, $code )

=item util( $name, %proto )

Define a utility function.

=cut

sub util {
    my ( $name, $code, $package, $proto ) = _util_args( @_ );
    croak( "No sub found for util $name" )
        unless $code;

    $SUBS{ $package }->{ $name } = $code;
}

=item tester( $name, $code )

=item tester( $name, %proto )

Define a tester function.

=cut

sub tester {
    my ( $name, $code, $package, $proto ) = _util_args( @_ );
    croak( "No sub found for tester $name" )
        unless $code;

    $code = _wrap_tester( $code, $proto );
    $SUBS{ $package }->{ $name } = $code;
}

sub _util_args {
    my $name = shift;
    my $code;
    my %proto;

    if ( @_ > 1 ) {
        %proto = @_;
        $code = $proto{ code } || "_$name";
    }
    else {
        ($code) = @_ ? @_ : "_$name";
    }

    $proto{ name } = $name;

    my ( $package ) = caller(1);
    $code = $package->can( $code ) unless !$code || ref( $code ) eq 'CODE';

    return ( $name, $code, $package, \%proto );
}

sub _record {
    my ( $result, $name, $time, @debug ) = @_;

    # Get the first caller outside of the plugin(s)
    my ( $package, $filename, $line ) = _first_non_plugin_caller();

    Test::Suite->get->result({
        result => $result || 0,
        name => $name || undef,
        package => $package || undef,
        filename => $filename || undef,
        line => $line || undef,
        time => defined( $time ) ? $time : undef,
        debug => \@debug,
        $TODO ? ( todo => $TODO ) : (),
    });
}

sub _wrap_tester {
    my ($code, $proto) = @_;
    my $prototype = prototype( $code );

    my $run = sub {
        my $count = @_;
        if ( my $max = $proto->{ max_args }) {
            croak( "Too many arguments for "  . $proto->{ name } . "() takes no more than $max, you gave $count" )
                unless @_ <= $max;
        }

        if ( my $min = $proto->{ min_args }) {
            croak( "Too few arguments for " . $proto->{ name } . "() requires $min, you gave $count" )
                unless $count >= $min;
        }

        _check_args( \@_, $proto->{ checks }) if $proto->{ checks };

        my $start = time();
        local $TB_USED = 0;
        my ( $result, $name, @debug ) = $code->( @_ );
        {
            no warnings 'numeric';
            return 1 if $result and $result == $NO_TEST;
        }
        if ( $TB_USED ) {
            ( $result, $name ) = @$Test::Builder::TBI_RESULT;
            @debug =  @Test::Builder::TBI_DIAGS;
        }
        _record( $result, $name, (time() - $start), @debug);
        return $result;
    };

    return $run unless $prototype;
    # If there is a prototype
    return eval "sub($prototype) { \$run->( \@_ ) }" || die($@);
}

sub _check_args {
    my ( $args, $checks ) = @_;
    return unless $args and @$args and $checks;

    if ( ref $checks eq 'ARRAY' ) {
        my %new;
        my $count = 0;
        map { $new{$count} = $_ if $_; $count++ } @$checks;
        $checks = \%new;
    }

    my @fails;
    NUM: for my $num ( keys %$checks ) {
        my $items = $checks->{ $num };
        my $val = $args->[$num];
        next unless defined($val);

        my $list = ref $items eq 'ARRAY' ? $items : [ $items ];
        for my $item ( @$list ) {
            if ( ref $item eq 'CODE' and !$item->( $val )){
                push( @fails, [$val, $items]);
                next NUM;
            }
            elsif ( ref $item eq 'Regexp' and $val !~ $item ) {
                push( @fails, [$val, $items]);
                next NUM;
            }
        }
    }
    return 1 unless @fails;

    for my $set ( @fails ) {
        my ( $val, $items ) = @$set;
        my $rtypes = { map { $TYPES{$_} => $_ } keys %TYPES };
        my $name = $rtypes->{ $items } || "";
        carp( "'$val' did not pass type constraint" . ($name ? " '$name'" : "") );
    }
    croak( "Type constraints did not pass" );
}

sub _first_plugin_caller {
    my ( $package, $filename, $line ) = _first_outside_caller();
    return undef unless $package && $package->isa( __PACKAGE__ );
    return ( $package, $filename, $line );
}

sub _first_outside_caller {
    my ( $package, $filename, $line );
    my $level = 0;
    do {
        ( $package, $filename, $line ) = caller($level++);
    } until( !$package || _not_masked_caller( $package, 0 ));
    return ( $package, $filename, $line );
}

sub _first_non_plugin_caller {
    my ( $package, $filename, $line );
    my $level = 0;
    do {
        ( $package, $filename, $line ) = caller($level++);
    } until( !$package || _not_masked_caller( $package, 1 ));
    return ( $package, $filename, $line );
}

sub _not_masked_caller {
    croak( "Not enough arguments for _not_masked_caller" )
        unless @_ >= 2;
    my ( $got, $isa, @not ) = (@_, @CARP_NOT);
    return !grep { ($got eq $_) ? 1 : ($isa ? $got->isa($_) : 0) } @not;
}

sub _ref_is {
    my ( $val, $type ) = @_;
    return 0 unless $val;
    return 0 unless my $ref = ref $val;
    return $_[0]->isa( $type ) if blessed( $_[0] );
    return $ref eq $type;
}


1;

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
