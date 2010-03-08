package Fennec::Runner::Root;
use strict;
use warnings;

use Cwd qw/cwd/;

sub new {
    my $class = shift;
    my ($in) = @_;
    return bless( \$in, $class );
}

sub path {
    my $self = shift;

    unless ( $$self ) {
        my $cd = cwd();
        my $root;
        do {
            $root = $cd if $self->_looks_like_root( $cd );
        } while !$root && $cd =~ s,/[^/]*$,,g && $cd;
        $root =~ s,/+$,,g;
        $$self = $root;
    }
    return $$self;
}

sub _looks_like_root {
    my $class = shift;
    my ( $dir ) = @_;
    return unless $dir;
    return 1 if -e "$dir/.fennec";
    return 1 if -d "$dir/t" && -d "$dir/lib";
    return 1 if -e "$dir/Build.PL";
    return 1 if -e "$dir/Makefile.PL";
    return 1 if -e "$dir/test.pl";
    return 0;
}

1;
