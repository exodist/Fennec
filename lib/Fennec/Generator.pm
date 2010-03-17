package Fennec::Generator;
use strict;
use warnings;

use Time::HiRes qw/time/;
use Benchmark qw/timeit :hireswallclock/;
use Carp qw/confess croak carp cluck/;
use Scalar::Util 'blessed';

our @EXPORT = ( qw/ generator util / );
our $NO_TEST = \"No Test";
our $TB_USED = 0;

sub export_to {
    my $class = shift;
    my ( $dest, $prefix ) = @_;
}

sub import {
    my $class = shift;
    my $caller = caller;

}

__END__

sub import {
    my $class = shift;
    my ( $arg ) = @_;
    return if $arg and $arg eq 'no_import';
    my ( $package ) = caller;

    no strict 'refs';
    *{ $package . '::' . $_ } = \&{ $_ } for @EXPORT;
}


sub export_to {
    my $class = shift;
    my ( $package, $prefix ) = @_;
    return 1 unless $package;

    return unless my $subs = $SUBS{ $class };

    for my $name ( keys %$subs ) {
        my $newname = $prefix ? "$prefix$name" : $name;
        no strict 'refs';
        *{ $package . '::' . $newname } = $subs->{ $name };
    }
}

sub no_test { return $NO_TEST }

sub util {
    my ( $name, $code, $package, $proto ) = _util_args( @_ );
    croak( "No sub found for util $name" )
        unless $code;

    $SUBS{ $package }->{ $name } = $code;
}

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

sub _result {
    my ( $ok, $name, $benchmark, @diag ) = @_;

    # Get the first caller outside of the plugin(s)
    my ( $package, $filename, $line ) = _first_non_plugin_caller();

    my $test = Fennec::Runner->get->test;
    my $case = $test ? $test->case : undef;
    my $set = $test ? $test->set : undef;

    my $result = Fennec::Result->new(
        result => $ok || 0,
        name   => $name,
        diag   => \@diag,
        case   => $case,
        set    => $set,
        test   => $test,
        line   => $line     || ($case ? $set ? $set->line : $case->line : undef),
        file   => $filename || ($case ? $set ? $set->filename : $case->filename : undef),
        $TODO ? ( todo => $TODO ) : (),
        benchmark   => $benchmark,
    );
    Fennec::Runner->get->result( $result );
}

sub _wrap_tester {
    my ($code, $proto) = @_;
    my $prototype = prototype( $code );

    my $run = sub {
        my @args = @_;
        my $count = @args;
        if ( my $max = $proto->{ max_args }) {
            croak( "Too many arguments for "  . $proto->{ name } . "() takes no more than $max, you gave $count" )
                unless @_ <= $max;
        }

        if ( my $min = $proto->{ min_args }) {
            croak( "Too few arguments for " . $proto->{ name } . "() requires $min, you gave $count" )
                unless $count >= $min;
        }

        _check_args( \@_, $proto->{ checks }) if $proto->{ checks };

        my ( $result, $name, @debug );
        local $TB_USED = 0;

        my $benchmark = timeit( 1, sub { ( $result, $name, @debug ) = $code->( @args ) });

        {
            no warnings 'numeric';
            return 1 if $result and $result == $NO_TEST;
        }
        if ( $TB_USED ) {
            ( $result, $name ) = @$Test::Builder::TBI_RESULT;
            @debug =  @Test::Builder::TBI_DIAGS;
        }

        _result( $result, $name, $benchmark, @debug);
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

