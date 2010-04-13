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

    tests 'SCALAR_compare undef' => sub {
        local *scomp = \&Fennec::Assert::Core::More::SCALAR_compare;
        ok( !scomp( \undef, \undef ), "Nothing when comparing nothing" );
        ok( my $err = scomp( \undef, \'a' ), "error when have is nothing" );
        ok( $err eq "Expected: 'a' Got: undef", "Correct error" ) || diag( $err );
        ok( $err = scomp( \'a', \undef ), "error when expected is nothing" );
        ok( $err eq "Expected: undef Got: 'a'", "Correct error" ) || diag( $err );
        ok( $err = scomp( \'undef', \undef ), "error when undef and string 'undef'" );
        ok( $err eq "Expected: undef Got: 'undef'", "Correct error" ) || diag( $err );
        ok( $err = scomp( \undef, \'undef' ), "error when 'undef' and undef" );
        ok( $err eq "Expected: 'undef' Got: undef", "Correct error" ) || diag( $err );
    };

    tests 'SCALAR_compare same' => sub {
        local *scomp = \&Fennec::Assert::Core::More::SCALAR_compare;
        ok( !scomp( \1, \1 ), "Same number");
        ok( !scomp( \0, \0 ), "Same number");
        ok( !scomp( \"aaa", \"aaa" ), "Same string" );
        ok( !scomp( qr/a/, qr/a/ ), "Same regex" );
    };

    tests 'SCALAR_compare different' => sub {
        my $self = shift;
        local *scomp = \&Fennec::Assert::Core::More::SCALAR_compare;
        local *msg = sub {
            my ( $h, $w ) = @_;
            ( $w, $h ) = String::Diff::diff( $w, $h )
                if $self->sd;
            $h = "'$h'";
            $w = "'$w'";
            return "Expected: $w Got: $h";
        };
        ok( my $err = scomp( \1, \2 ), "Different number");
        ok( $err eq msg( 1, 2 ), "Correct msg" ) || diag( $err );
        ok( $err = scomp( \1, \0 ), "Different number");
        ok( $err eq msg( 1, 0 ), "Correct msg" );
        ok( $err = scomp( \0, \1 ), "Different number");
        ok( $err eq msg( 0, 1 ), "Correct msg" );
        ok( $err = scomp( \"aaa", \"bbb" ), "Different string" );
        ok( $err eq msg( 'aaa', 'bbb' ), "Correct msg" );
        ok( $err = scomp( qr/a/, qr/b/ ), "Different regex" );
        ok( $err eq msg( qr/a/, qr/b/ ), "Correct msg" );
    };

};

describe 'Primary tests' => sub {
    my $self = shift;
    before_each {
        $self->sd( 0 );
        $Fennec::Assert::Core::More::DIFF = 0;
    };

    it is_fail => sub {
        my $fail = capture {
            is( 'a', 'b', 'ab' );
            is( 0, 1, '01' );
            is( 1, 0, '10' );
            is( 1, 2, '12' );
            is( undef, 'a', 'ua' );
            is( 'a', undef, 'au' );
            is( qr/a/, qr/b/, 'regex' );
        };
        ok( @$fail == 7, 'num failed' );
        ok( !$fail->[$_]->pass, "$_ failed" ) for 0 .. @$fail - 1;
        ok(
            "ab-01-10-12-ua-au-regex"
            eq
            join('-', map { $_->name } @$fail ),
            "fail names"
        );
        is_deeply(
            [ map { @{ $_->stderr }} @$fail ],
            [
                qq/Expected: 'b' Got: 'a'/,
                qq/Expected: '1' Got: '0'/,
                qq/Expected: '0' Got: '1'/,
                qq/Expected: '2' Got: '1'/,
                qq/Expected: 'a' Got: undef/,
                qq/Expected: undef Got: 'a'/,
                "Expected: '" . qr/b/ . "' Got: '" . qr/a/ . "'",
            ],
            "Correct errors"
        );
    };

    it is_pass => sub {
        my $pass = capture {
            is( 'a', 'a', 'a' );
            is( 1, 1, 'one' );
            is( 0, 0, 'zero' );
            is( undef, undef, 'undef' );
            is( qr/a/, qr/a/, 'regex' );
        };
        ok( @$pass == 5, 'num passed' );
        ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. @$pass - 1;
        ok(
            "a-one-zero-undef-regex"
            eq
            join('-', map { $_->name } @$pass),
            "pass names"
        ) || diag( "a-1-0-undef-regex", join('-', map { $_->name } @$pass));
    };

    it isnt => sub {
        my $pass = capture {
            isnt( 'a', 'b', 'ab' );
            isnt( 0, 1, 'zero-one' );
            isnt( 1, 2, 'one-two' );
            isnt( undef, 1, "und-one" );
            isnt( qr/a/, qr/b/, 'regex' );
        };
        my $fail = capture {
            isnt( 'a', 'a', 'aa' );
            isnt( qr/a/, qr/a/, 'regex2' );
        };
        is( @$pass, 5, "5 passes" );
        is( @$fail, 2, "2 fails" );
        ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. @$pass - 1;
        ok( !$fail->[$_]->pass, "$_ failed" ) for 0 .. @$fail - 1;
        is_deeply(
            [ map { @{ $_->stderr }} @$fail ],
            [
                "Got: 'a' Wanted: Anything else",
                "Got: '" . qr/a/ . "' Wanted: Anything else",
            ],
            "Correct errors"
        );
    };


};

1;

__END__

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
    $have = $$have unless (blessed( $have ) || '') eq 'Regexp';
    $want = $$want unless (blessed( $want ) || '') eq 'Regexp';

    return if !defined( $have ) && !defined( $want );
    my $bad = (!$have && $want) || (!$want && $have);
    return if !$bad && "$have" eq "$want";

    if ( $DIFF && defined( $want ) && defined( $have )) {
        ( $want, $have ) = String::Diff::diff( $want, $have );
    }
    $want = defined( $want ) ? "'$want'" : 'undef';
    $have = defined( $have ) ? "'$have'" : 'undef';
    return ( "Expected: $want Got: $have" );
}

sub CODE_compare {
    my ( $have, $want, $specs ) = @_;
    return if $specs->{ no_code_checks };
    print STDERR "C\n";
    my $msg = "Expected: '$want' Got: '$have'";
    return $msg unless $have == $want;
}

1;
