package Fennec::Tester::Files;
use strict;
use warnings;

use File::Find   qw/find/;

sub files {
    my $self = shift;

    unless ( $self->{ files }) {
        my $root = $self->root;
        my @files;
        my $wanted = sub {
            no warnings 'once';
            my $file = $File::Find::name;
            return unless $file =~ m/\.pm$/;
            return if grep { $file =~ $_ } @{ $self->ignore };
            push @files => $file;
        };
        my @paths;
        push @paths => "$root/ts" if -e "$root/ts";
        push @paths => "$root/lib" if $self->inline && -e "$root/lib";
        find( $wanted, @paths ) if @paths;
        $self->{ files } = \@files;
    }

    return $self->{ files };
}

sub load_files {
    my $self = shift;
    for my $file ( @{ $self->files }) {
        eval { require $file } || push @{ $self->bad_files } => [ $file, $@ ];
    }
}


