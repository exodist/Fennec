#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;

my $CLASS = 'Test::Suite';

lives_ok { eval "require $CLASS" || die( $@ )} "Loaded $CLASS";

done_testing;
