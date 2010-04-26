package Fennec::FileLoader;
use strict;
use warnings;

use Carp;
use Fennec::Output::Result;
require Fennec;

use Cwd qw/cwd/;

our $ROOT;

sub root {
    my $class = shift;
    unless ( $ROOT ) {
        my $cd = cwd();
        my $root;
        do {
            $root = $cd if $class->_looks_like_root( $cd );
        } while !$root && $cd =~ s,/[^/]*$,,g && $cd;
        $root =~ s,/+$,,g;
        $ROOT = $root;
    }
    return $ROOT;
}

sub _looks_like_root {
    my $class = shift;
    my ( $dir ) = @_;
    return unless $dir;
    return 1 if -d "$dir/t" && -d "$dir/lib";
    return 1 if -e "$dir/Build.PL";
    return 1 if -e "$dir/Makefile.PL";
    return 1 if -e "$dir/test.pl";
    return 1 if -e "$dir/t/Fennec.t";
    return 0;
}

sub find_types {
    my $class = shift;
    my ( $types, $files ) = @_;

    my @plugins;
    for my $type ( @$types ) {
        my $plugin = "Fennec\::FileType\::$type";
        eval "require $plugin" || die( $@ );
        push @plugins => $plugin;
    }

    return $class->find_all( @plugins )
        unless $files;

    my @out;
    for my $file ( @$files ) {
        for my $plugin ( @plugins ) {
            if ( $plugin->valid_file( $file )) {
                push @out => $plugin->new( $file );
                last;
            }
        }
    }

    return @out;
}

sub find_all {
    my $class = shift;
    my @plugins = @_;
    my @out;
    for my $plugin ( @plugins ) {
        push @out => $plugin->find();
    }
    return @out;
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
