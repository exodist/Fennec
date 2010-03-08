#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Files;

my $CLASS = 'Fennec::Files::Offset';
use_ok( $CLASS );

my $wanted;
{
    no warnings 'once';
    $wanted = \%Fennec::Files::WANTED;
}

ok( $wanted->{ Offset }, "Added Offset" );
isa_ok( $wanted->{ Offset }->[0], 'Regexp' );
isa_ok( $wanted->{ Offset }->[1], 'CODE' );

like( '/lib/TEST/A.pm', $wanted->{ Offset }->[0], "Matched lib/TEST/" );
like( '/lib/A/TEST/B.pm', $wanted->{ Offset }->[0], "Matched lib/A/TEST/" );
ok( '/lib/A.pm' !~ $wanted->{ Offset }->[0], "No match w/o TEST" );
ok( '/t/TEST/A.pm' !~ $wanted->{ Offset }->[0], "No match in t/" );

done_testing;
