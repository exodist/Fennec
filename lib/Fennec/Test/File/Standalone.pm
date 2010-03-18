package Fennec::Test::File::Standalone;
use strict;
use warnings;

use base 'Fennec::Test::File';

sub valid_file { 1 }
sub load_file {
    my $class = shift;
    my ( $tclass ) = @_;
    $Fennec::TEST_CLASS = $tclass;
    $tclass->Fennec;
}
sub paths {}

1;
