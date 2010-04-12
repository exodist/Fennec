package TEST::Fennec::Assert::Core::More;
use strict;
use warnings;

use Fennec workflows => [qw/Case Spec/];
use Fennec::Util::Accessors;

Accessors qw/ sd /;

our $CLASS = 'Fennec::Assert::Core::More';
eval "require $CLASS; 1" || die ( $@ );

cases 'String::Diff' => sub {
    my $self = shift;
    my $sd = eval 'require String::Diff; 1';

    case no_string_diff => sub {
        $self->sd( 0 );
        $Fennec::Assert::Core::More::DIFF = 0;
    };

    case string_diff => sub {
        $self->sd( 1 );
        $Fennec::Assert::Core::More::DIFF = 1;
    } if $sd;

    tests SCALAR_compare => sub {

    };
};

describe 'Primary tests' => sub {
    my $self = shift;
    before_each {
        $self->sd( 0 );
        $Fennec::Assert::Core::More::DIFF = 0;
    };
};

1;

__END__

BEGIN { $DIFF = eval 'require String::Diff; 1' ? 1 : 0 }

tester( $_ ) for qw/is isnt like unlike can_ok isa_ok is_deeply advanced_is/;

sub is($$;$) {
    my ( $got, $want, $name ) = @_;
    my ($err) = SCALAR_compare( \$got, \$want );
    result(
        pass => !$err,
        name => $name,
        $err ? ( stderr => [ $err ]) : (),
    );
}

sub isnt($$;$) {
    my ( $got, $nowant, $name ) = @_;
    my ($err) = SCALAR_compare( \$got, \$nowant );
    result(
        pass => $err ? 1 : 0,
        name => $name,
        $err ? () : ( stderr => [ "Got: $got", "Wanted: Anything else" ]),
    );
}

sub like($$;$) {
    my ( $thing, $check, $name ) = @_;
    my $regex = ref $check eq 'Regexp' ? $check : qr{$check};
    my $ok = $thing =~ $check;
    result(
        pass => $ok,
        name => $name,
        $ok ? () : ( stderr => [ "$thing does not match $check" ]),
    );
}

sub unlike($$;$) {
    my ( $thing, $check, $name ) = @_;
    my $regex = ref $check eq 'Regexp' ? $check : qr{$check};
    my $ok = $thing !~ $check;
    result(
        pass => $ok,
        name => $name,
        $ok ? () : ( stderr => [ "$thing matches $check (it shouldn't)" ]),
    );
}

sub can_ok(*;@) {
    my ( $thing, @stuff ) = @_;
    my $name = "$thing\->can(...)";
    return result(
        pass => 0,
        name => $name,
        stderr => ["$thing is an unblessed reference"],
    ) if ref( $thing ) && !blessed( $thing );
    my @err = map { $thing->can( $_ ) ? () : "$thing cannot $_"} @stuff;
    result(
        pass => @err ? 0 : 1,
        name => $name,
        stderr => \@err,
    );
}

sub isa_ok(*@) {
    my ( $thing, @stuff ) = @_;
    my $name = "$thing\->isa(...)";
    return result(
        pass => 0,
        name => $name,
        stderr => ["$thing is an unblessed reference"],
    ) if ref( $thing ) && !blessed( $thing );
    my @err = map { $thing->isa( $_ ) ? () : "$thing is not a $_"} @stuff;
    result(
        pass => @err ? 0 : 1,
        name => $name,
        stderr => \@err,
    );
}

sub is_deeply($$;$) {
    my ( $have, $want, $name ) = @_;
    return advanced_is( got => $have, want => $want, name => $name );
}

sub advanced_is {
    my %proto = @_;
    croak( "You must specify got and want" ) unless exists $proto{ got }
                                                 && exists $proto{ want };
    my ( $have, $want, $name ) = @proto{qw/got want name/};
    my @err = compare( $have, $want, \%proto );
    result(
        pass => @err ? 0 : 1,
        name => $name || undef,
        stderr => \@err,
    );
}

sub compare($$;$) {
    my ( $have, $want, $specs ) = @_;
    return ("Not enough arguments")
        unless @_ > 1;

    return if !defined( $have ) && !defined( $want );

    if ( !defined( $have ) || !defined( $want )) {
        return (
            "Expected: '"
            . (defined( $want ) ? $want : 'undef')
            . "' Got: '"
            . (defined( $have ) ? $have : 'undef')
            . "'"
        ) if defined( $have ) || defined( $want );
    }

    return SCALAR_compare( \$have, \$want, $specs )
        unless ref( $want ) || ref( $have );

    my $haveref = reftype( $have ) || $have || "undef";
    my $wantref = reftype( $want ) || $want || "undef";
    return ( "Expected: '$wantref' Got: '$haveref'" )
        unless( "$haveref" eq "$wantref" );

    my @err;
    push @err => compare_bless( $have, $want )
        if $specs->{ bless };

    no strict 'refs';
    push @err => &{ "$haveref\_compare" }( $have, $want, $specs );
    return @err;
}

sub ARRAY_compare {
    my ( $have, $want, $specs ) = @_;
    my $max = @$have > @$want ? @$have : @$want;
    my @err;
    for my $i ( 0 .. ($max - 1)) {
        push @err => map { "[$i] $_" }
            compare(
                $have->[$i] || undef,
                $want->[$i] || undef,
                $specs
            );
    }
    return @err;
}

sub HASH_compare {
    my ( $have, $want, $specs ) = @_;
    my %keyholder = map {( $_ => 1 )} keys %$have, keys %$want;
    my @err;
    for my $key ( keys %keyholder ) {
        push @err => map { "{'$key'} $_" }
            compare(
                $have->{$key} || undef,
                $want->{$key} || undef,
                $specs,
            );
    }
    return @err;
}

sub SCALAR_compare {
    my ( $have, $want, $specs ) = @_;
    $have = $$have unless blessed( $have ) || '' eq 'Regexp';
    $want = $$want unless blessed( $want ) || '' eq 'Regexp';

    return if !defined( $have ) && !defined( $want );
    my $bad = (!$have && $want) || (!$want && $have);
    return if !$bad && "$have" eq "$want";

    if ( $DIFF && defined( $want ) && defined( $have )) {
        ( $want, $have ) = String::Diff::diff( $want, $have );
    }
    $want = 'undef' unless defined( $want );
    $have = 'undef' unless defined( $have );
    return ( "Expected: '$want' Got: '$have'" );
}

sub CODE_compare {
    my ( $have, $want, $specs ) = @_;
    return if $specs->{ no_code_checks };
    print STDERR "C\n";
    my $msg = "Expected: '$want' Got: '$have'";
    return $msg unless $have == $want;
}

1;
