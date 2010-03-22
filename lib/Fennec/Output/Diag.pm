package Fennec::Output::Diag;
use strict;
use warnings;

use base 'Fennec::Output';

sub new {
    my $class = shift;
    return bless( { @_ }, $class );
}


1;
