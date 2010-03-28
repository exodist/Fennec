package Fennec::FileLoader::Standalone;
use strict;
use warnings;

use base 'Fennec::FileLoader';

sub valid_file { 1 }
sub load_file {
    my $class = shift;
    my ( $tcaller ) = @_;
    my ( $tclass ) = @$tcaller;
    $Fennec::TEST_CLASS = $tclass;
    $tclass->Fennec;
}
sub paths {}

sub filename {
    my $self = shift;
    $self->[0]->[1];
}

1;
