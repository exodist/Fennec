package Fennec::Assert::Core::More;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Output::Result;
use Scalar::Util qw/blessed reftype/;
use Carp;
our $DIFF;
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
        $err ? () : ( stderr => [ "Got: '$got' Wanted: Anything else" ]),
    );
}

sub like($$;$) {
    my ( $thing, $check, $name ) = @_;
    my $regex = ref $check eq 'Regexp' ? $check : qr{$check};
    my $ok = $thing =~ $check;
    result(
        pass => $ok,
        name => $name,
        $ok ? () : ( stderr => [ "'$thing' does not match $check" ]),
    );
}

sub unlike($$;$) {
    my ( $thing, $check, $name ) = @_;
    my $regex = ref $check eq 'Regexp' ? $check : qr{$check};
    my $ok = $thing !~ $check;
    result(
        pass => $ok,
        name => $name,
        $ok ? () : ( stderr => [ "'$thing' matches $check (it shouldn't)" ]),
    );
}

sub can_ok(*;@) {
    my ( $thing, @stuff ) = @_;
    my $name = defined($thing) ? "$thing\->can(...)" : "undef\->can(...)";
    return result(
        pass => 0,
        name => $name,
        stderr => [ (defined($thing) ? "'$thing'" : 'undef') . " is not blessed or class name"],
    ) if !blessed( $thing ) && !eval { $thing->can( 'can' ) ? 1 : 0 };
    my @err = map { $thing->can( $_ ) ? () : "'$thing' cannot '$_'"} @stuff;
    result(
        pass => @err ? 0 : 1,
        name => $name,
        stderr => \@err,
    );
}

sub isa_ok(*@) {
    my ( $thing, @stuff ) = @_;
    my $name = defined($thing) ? "$thing\->isa(...)" : "undef\->isa(...)";
    return result(
        pass => 0,
        name => $name,
        stderr => [ (defined($thing) ? "'$thing'" : 'undef') . " is not blessed or class name"],
    ) if !blessed( $thing ) && !eval { $thing->can( 'can' ) ? 1 : 0 };
    my @err = map { $thing->isa( $_ ) ? () : "'$thing' is not a '$_'"} @stuff;
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
    my @err;
    push @err => "You must specify 'got' and 'want'" unless exists $proto{ got }
                                                         && exists $proto{ want };
    use Data::Dumper;
    my ( $have, $want, $name ) = @proto{qw/got want name/};
    unless( @err ) {
        @err = compare( $have, $want, \%proto );
    }
    result(
        pass => @err ? 0 : 1,
        name => $name || 'unnamed test',
        stderr => \@err,
    );
}

sub compare($$;$) {
    my ( $have, $want, $specs ) = @_;
    return ("Not enough arguments")
        unless @_ > 1;

    return if !defined( $have ) && !defined( $want );

    return SCALAR_compare( \$have, \$want, $specs )
        if ( !defined( $have ) || !defined( $want ));

    return SCALAR_compare( \$have, \$want, $specs )
        unless ref( $want ) || ref( $have );

    my $haveref = reftype( $have ) || $have || "undef";
    my $wantref = reftype( $want ) || $want || "undef";
    return ( "Expected: '$wantref' Got: '$haveref'" )
        unless( "$haveref" eq "$wantref" );

    my @err;
    push @err => _compare_bless( $have, $want )
        if $specs->{ bless };

    no strict 'refs';
    push @err => &{ "$haveref\_compare" }( $have, $want, $specs );
    return @err;
}

sub _compare_bless {
    my ( $have, $want ) = @_;
    $have = blessed( $have ) ? 'bless( $obj, "' . blessed( $have ) . '" )' : 'not blessed';
    $want = blessed( $want ) ? 'bless( $obj, "' . blessed( $want ) . '" )' : 'not blessed';
    return SCALAR_compare( \$have, \$want );
}

sub ARRAY_compare {
    my ( $have, $want, $specs ) = @_;
    my $max = @$have > @$want ? @$have : @$want;
    my @err;
    for my $i ( 0 .. ($max - 1)) {
        push @err => map { "[$i]" . ($_ =~ m/^[\[\{]/ ? "$_" : " $_") }
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
        push @err => map { "{$key}" . ($_ =~ m/^[\[\{]/ ? "$_" : " $_") }
            compare(
                $have->{$key} || undef,
                $want->{$key} || undef,
                $specs,
            );
    }
    return @err;
}

sub REGEXP_compare { goto &SCALAR_compare }

sub SCALAR_compare {
    my ( $have, $want ) = @_;
    $have = $$have unless (blessed( $have ) || '') eq 'Regexp';
    $want = $$want unless (blessed( $want ) || '') eq 'Regexp';

    return if !defined( $have ) && !defined( $want );
    my $bad = (defined($have) && !defined($want)) || (defined($want) && !defined($have));
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
    return if $specs->{ no_code_checks } || $have == $want;
    return ( "Expected: '$want' Got: '$have'" );
}

1;

__END__

=pod

=head1 NAME

Fennec::Assert::Core::More - Assertion library that mirrors L<Test::More>'s
functionality.

=head1 DESCRIPTION

This assertion library exports testers nearly identical to those in
L<Test::More>. There have been a couple changes in output, and some have been
expanded to be more flexible, however they should be almost completely
compatible with L<Test::More>'s.

=head1 TESTERS

These are exported for use within tests, each one generates at least 1 result.

=over 4

=item is($got, $want; $name)

Tests that $got == $want. Works for any scalar value, references must be the
same reference or they will fail, if an argument is an array it will compare
its size to the other argument.

=item isnt($got, $want; $name)

The inverse of is, test passes if $got and $want are not the same.

=item like($got, $want; $name)

Checks $got against $want, $want can be a qr// style regex, or a string which
will be used inside a regex.

=item unlike($got, $want; $name)

Inverse of like, true if $got does not match $want.

=item can_ok(*thing; @list )

Tests that *thing is a class name, or object that implements the listed
methods. *thing can be a bareword, the name of a class in a string, or a
blessed object.

=item isa_ok(*thing; @list )

Tests that *thing is a class name, or object that has each item from @list in
its inheritance. *thing can be a bareword, the name of a class in a string, or
a blessed object.

=item is_deeply($got, $want; $name)

Compare one data structure to another. It will ignore blessed status of any
objects. ['a'] and bless(['a'], 'XXX') will be considered the same, as will
bless(['a'], 'XXX') and bless(['a'], 'YYY' ). CODE refs must be the same
reference or they will fail, there is not currently a (good) way to verify 2
CODE references are identical.

=item advanced_is(got => $got, want => $want, name => $name, %options)

Like is_deeply except you can pass in extra options to control comparisons.

Options:

    advanced_is(
        ...
        # Verify blessed things are blessed in both datastructures, and blessed
        # as the same class.
        bless => 1,

        # Do not compare codereferences, just ensure both datastructures have a
        # coderef at the same point.
        no_code_checks => 1,
    )

=back

=head1 INTERNAL API FUNCTIONS

These are functions that work behind the scenes to do the tests. They may be
useful in other assertion libraries, they are documented here for that reason,
none are exported, you must manually import them, or use them with the fully
qualified package name.

=over 4

=item @errors = compare($got, $want; $specs)

Used by is_deeply() and is_advanced(). Compares the datastructures $got and
$want and returns any differences in error form. The messages will take the
form of a location identifier '{a}[1]{b}[4]...' showing the point in the
datastructure that differs, followed by what was expected and what was found.

$specs is a hashref containing extra arguments available to is_advanced().

=item @errors = ARRAY_compare($got, $want; $specs)

Used buy compare() to compare 2 arrays. Datastructures nested within the array
will also be compared.

=item @errors = HASH_compare($got, $want; $specs)

Used by compare() to compare 2 hashes. Datastructures nested within the array
will also be compared.

=item @errors = REGEXP_compare( \$got, \$want )

Alias to SCALAR_compare().

I<In perl 5.12.0 REGEXPs have become a proper type, in older versions this is
never used>

=item @errors = SCALAR_compare(\$got, \$want)

NOTE: $got and $want must be references to scalars being compared, not the
scalars themselves.

Used anywhere 2 scalars are compared, that includes qr// style regex's.

=item @errors = CODE_compare($got, $want; $specs)

Used by compare() to compare 2 CODE refs.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
