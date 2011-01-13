package Fennec::Base;
use strict;
use warnings;

sub new { bless( {}, shift )}

sub run {
    my $self = shift;
    print "Running: $self\n";
}

1;
