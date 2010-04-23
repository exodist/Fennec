package Fennec::Assert::Core::Warn;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Assert::Core::More;
use Fennec::Output::Result;

util $_ for qw/warning_is warnings_are warning_like capture_warnings/;
tester $_ for qw/warnings_like warnings_exist/;

sub capture_warnings(&) {
    my ( $sub ) = @_;
    my @warns;
    local $SIG{ __WARN__ } = sub { push @warns => @_ };
    $sub->();
    return @warns
}

sub warning_is(&$;$) {
    my ( $sub, $match, $name ) = @_;
    my @warns = capture_warnings( \&$sub );
    return result(
        pass => 0,
        name => $name,
        stderr => [ "Too many warnings:", map { "\t$_" } @warns ],
    ) if @warns > 1;

    return is( $warns[0], $match, $name );
}

sub warnings_are(&$;$) {
    my ( $sub, $matches, $name ) = @_;
    my @warns = capture_warnings( \&$sub );
    return is_deeply( \@warns, $matches, $name );
}

sub warning_like(&$;$) {
    my ( $sub, $match, $name ) = @_;
    my @warns = capture_warnings( \&$sub );

    return result(
        pass => 0,
        name => $name,
        stderr => [ "Too many warnings:", map { "\t$_" } @warns ],
    ) if @warns > 1;

    return result(
        pass => 0,
        name => $name,
        stderr => [ "Did not warn as expected" ],
    ) if !@warns;

    return like( $warns[0], $match, $name );
}

sub warnings_like(&$;$) {
    my ( $sub, $matches, $name ) = @_;
    my @warns = capture_warnings( \&$sub );

    return result(
        pass => 0,
        name => $name,
        stderr => [ "Wrong number of warnings:", map { "\t$_" } @warns ],
    ) if @warns != @$matches;

    my @fail;
    for my $i ( 0 .. ( @warns - 1 )) {
        next if $warns[$i] =~ $matches->[$i];
        push @fail => "'" . $warns[$i] . "' does not match '" . $matches->[$i] . "'";
    }

    result(
        pass => @fail ? 0 : 1,
        name => $name,
        @fail ? ( stderr => \@fail ) : (),
    );
}

sub warnings_exist(&$;$) {
    my ( $sub, $in, $name ) = @_;
    my $matches = ref($in) eq 'ARRAY' ? $in : [ $in ];
    my @warns = capture_warnings( \&$sub );
    my %found;
    my @extra;
    for my $warn ( @warns ) {
        my $matched = 0;
        for my $match ( @$matches ) {
            if ( ref( $match ) ? $warn =~ $match : $match eq $warn ) {
                $found{ $match }++;
                $matched++;
            }
        }
        push @extra => $warn unless $matched;
    }
    my @missing = grep { !$found{$_} } @$matches;
    result(
        pass => @missing ? 0 : 1,
        name => $name,
        stderr => [
            @missing ? ( "Missing warnings:", map { "\t$_" } @missing )
                     : (),
            (@missing && @extra) ? ( "Extra warnings (not an error):", map { "\t$_" } @extra )
                   : (),
        ]
    );
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
