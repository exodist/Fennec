#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    package My::Fennec;
    $INC{'My/Fennec.pm'} = __FILE__;
    use base 'Fennec';
    
    sub after_import {
        my $class = shift;
        my ($info) = @_;
   
        my @caller = caller(1);

        $info->{layer}->add_case(\@caller, case_a => sub { $main::CASE_A = 1 });
        $info->{layer}->add_case(\@caller, case_b => sub { $main::CASE_B = 1 });
    }
}

use My::Fennec;

tests both_cases => sub {
    ok( $main::CASE_A || $main::CASE_B, "In a case" );
    ok( !($main::CASE_A && $main::CASE_B), "Not in both cases" );
};

done_testing;
