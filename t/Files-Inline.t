#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Files;

my $CLASS = 'Fennec::Files::Inline';
use_ok( $CLASS );

my $wanted;
{
    no warnings 'once';
    $wanted = \%Fennec::Files::WANTED;
}

ok( $wanted->{ Inline }, "Added Inline" );
isa_ok( $wanted->{ Inline }->[0], 'Regexp' );
isa_ok( $wanted->{ Inline }->[1], 'CODE' );

like( '/lib/A.pm', $wanted->{ Inline }->[0], "Matched lib/A.pm" );
like( '/lib/A/B.pm', $wanted->{ Inline }->[0], "Matched lib/A/B.pm" );
ok( '/t/A.pm' !~ $wanted->{ Inline }->[0], "No match t/*.pm" );
ok( '/t/test.t' !~ $wanted->{ Inline }->[0], "No match .t files" );

done_testing;
