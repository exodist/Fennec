package Fennec::Listener;
use strict;
use warnings;

use Carp qw/croak/;

sub new { croak "You must subclass new() in your listener(" . shift(@_) . ")" }
sub ok  { croak "You must subclass ok() in your listener(" . shift(@_) . ")"  }
sub terminate {}

1;
