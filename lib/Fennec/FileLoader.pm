package Fennec::FileLoader;
use strict;
use warnings;

use Carp;
use Fennec::Output::Result;
use Fennec::Util::Abstract;
require Fennec;

use List::MoreUtils qw/uniq/;
use Cwd qw/cwd/;
use File::Find qw/find/;
BEGIN {
    *_find = \&find;
    undef( *Fennec::FileLoader::find );
}

our $ROOT;

Abstract qw/ valid_file load_file paths /;

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
    my @paths;

    my @plugins;
    for my $type ( @$types ) {
        my $plugin = "Fennec\::FileLoader\::$type";
        eval "require $plugin" || die( $@ );
        push @plugins => $plugin;
        push @paths => $plugin->paths;
    }
    @paths = uniq @paths;

    unless ( $files ) {
        $files = [];
        _find(
            sub { push @$files => $File::Find::name },
            map { $class->root . "/$_" } @paths
        );
    }

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

sub find {
    my $class = shift;
    my @list;
    _find(
        sub {
            my $file = $File::Find::name;
            return unless $class->valid_file( $file );
            push @list => $file;
        },
        map { $class->root . "/$_" } $class->paths
    ) if $class->paths;

    return map { $class->new( $_ ) } @list;
}

sub new {
    my $class = shift;
    my ( $file ) = @_;

    croak( "$class\::new() called without a filename" )
        unless $file;
    croak( "$file is not a valid $class file" )
        unless $class->valid_file( $file );

    return bless( [ $file, 0 ], $class );
}

sub data {
    my $self = shift;
    ( $self->[2] ) = @_ if @_;
    return $self->[2];
}

sub load {
    my $self = shift;
    return 1 if $self->[1]++;
    Fennec->clear_test_class;

    $self->load_file( $self->[0] );

    my $tclass = Fennec->test_class;
    croak( "loading '" . $self->[0] . "' did not produce a test class" )
        unless $tclass;
    return $tclass;
}

sub filename {
    my $self = shift;
    $self->[0];
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
