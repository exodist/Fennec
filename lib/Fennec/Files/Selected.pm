package Fennec::Files::Selected;
use strict;
use warnings;

use Fennec::Files qw/add_to_wanted/;

sub select {
    my $class = shift;
    my %map = @_;
    add_to_wanted(
        'Selected',
        sub {
            my $file = shift;
            my $out = $map{ $file } ? 1 : 0;
            print STDERR "File: $file\n" if $out;
            $out;
        },
        sub {
            my $file = shift;
            my $type = $map{ $file };
            return Fennec::Files->wanted->{ $type }->[1]->( $file );
        }
    );
}

1;
