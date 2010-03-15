package Fennec::File;
use strict;
use warnings;
use Carp;
use Fennec::Runner::Root;
use Fennec::Result;
use Try::Tiny;

use File::Find qw/find/;
BEGIN {
    *_find = \&find;
    undef( &find );
}

sub valid_file {}
sub load_file {}
sub paths {}

sub find {
    my $class = shift;
    my $root = Fennec::Runner::Root->new->path;
    my @list;
    find(
        sub {
            my $file = $File::Find::name;
            return unless $class->valid_file( $file );
            push @list => $file;
        },
        $self->paths
    ) if $self->paths;

    return map { $class->new( $_ ) } @list;
}

sub new {
    my $class = shift;
    my ( $file ) = @_;

    croak( "$class\::new() called without a filename" )
        unless $file;
    croak( "$file is not a valid $class file" )
        unless $self->valid_file( $file );

    return bless( [ $file, 0 ], $class );
}

sub load {
    my $self = shift;
    return if $self->[1]++;
    try {
        $self->load_file( $self->[0] );
    } catch {
        Fennec::Runner->get->direct_result( Fennec::Result->new(
            result => 0,
            name   => "Load file $file",
            diag   => [ "Failure loading file: $file", $_ ],
            case   => undef,
            set    => undef,
            test   => undef,
            line   => "N/A",
            file   => $self->filename,
            benchmark   => undef,
        ));
    };
}

sub filename {
    my $self = shift;
    $self->[0];
}

1;
