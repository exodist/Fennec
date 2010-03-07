package Fennec::Files;
use strict;
use warnings;

use File::Find qw/find/;
use Fennec::Util qw/add_accessors/;

add_accessors qw/bad_files/;

sub files {
    my $self = shift;

    unless ( $self->{ files }) {
        my $root = Fennec::Runner->get->root->path;
        my @files;
        my $wanted = sub {
            no warnings 'once';
            my $file = $File::Find::name;
            return unless $file =~ m/\.pm$/;
            return if grep { $file =~ $_ } @{ Fennec::Runner->get->ignore };
            # Do not load actual libraries unless inline is specified
            return if !Fennec::Runner->get->inline
                   && $file =~ m,$root/lib,
                   && !$file =~ m,/TEST/,;
            push @files => $file;
        };
        my @paths = ( "$root/t", "$root/lib" );
        #push @paths => "$root/lib" if $self->inline && -e "$root/lib";
        find( $wanted, @paths ) if @paths;
        $self->{ files } = \@files;
    }

    return $self->{ files };
}

sub load {
    my $self = shift;
    for my $file ( @{ $self->files }) {
        eval { require $file } || push @{ $self->bad_files } => [ $file, $@ ];
    }
}

1;
