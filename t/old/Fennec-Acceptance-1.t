#!/usr/bin/perl
use strict;
use warnings;

my $tester;
BEGIN {
    require Fennec::Runner;
    $tester = Fennec::Runner->new( _config => 1, no_load => 1, files => [ 'ts/001Acceptance.pm' ]);
}
$tester->load_files;
$tester->run;

1;
