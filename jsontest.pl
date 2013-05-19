#!/usr/bin/env perl
use strict;
use warnings;

use JSON qw/from_json/;
use Data::Dumper;

open( my $file, '<', $ARGV[0] ) || die "Error $ARGV[0], $!";
my $data = join "" => <$file>;
print Dumper( from_json($data) );

