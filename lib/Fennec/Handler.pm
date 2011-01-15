package Fennec::Handler;
use strict;
use warnings;

sub handle { die( shift . " Does not implement 'handle'") }

sub exit { die( shift . " Does not implement 'exit'" ) }

1;
