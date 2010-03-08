#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Files;

my $CLASS = 'Fennec::Files::TDir';
use_ok( $CLASS );

my $wanted;
{
    no warnings 'once';
    $wanted = \%Fennec::Files::WANTED;
}

ok( $wanted->{ TDir }, "Added TDir" );
isa_ok( $wanted->{ TDir }->[0], 'Regexp' );
isa_ok( $wanted->{ TDir }->[1], 'CODE' );

like( '/t/A.pm', $wanted->{ TDir }->[0], "Matched t/A.pm" );
like( '/t/A/B.pm', $wanted->{ TDir }->[0], "Matched t/A/B.pm" );
ok( '/lib/A.pm' !~ $wanted->{ TDir }->[0], "No match in lib" );
ok( '/t/test.t' !~ $wanted->{ TDir }->[0], "No match .t files" );

done_testing;
