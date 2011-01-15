package Fennec::IO::Handle;
use strict;
use warnings;

use Data::Dumper;
use Fennec::Util qw/accessors/;
accessors qw/prefix/;

sub TIEHANDLE {
    my $class = shift;
    my ( $prefix ) = @_;

    my $self = bless( \$prefix, $class );

    return $self;
}

sub PRINT {
    my $self = shift;
    require Fennec::IO;
    my $out = Fennec::IO->write_handle;
    local $/ = Fennec::IO->FOS;
    print $out $$self, " $$ :", @_, $/;
}

1;
