package Fennec::Finder;
use strict;
use warnings;

use base 'Fennec::Runner';
use File::Find qw/find/;

sub import {
    my $self = shift->new;
    $self->find_files( @_ );
    $self->inject_run( scalar caller )
}

sub find_files {
    my $self = shift;
    my @paths = @_;

    unless( @paths ) {
        @paths = -d './t' ? ( './t' ) : ( './' );
    }

    find(
        {
            wanted => sub {
                my $file = $File::Find::name;
                return unless $file =~ m{\.pm$};
                $self->load_file( $file );
            },
            no_chdir => 1,
        },
        @paths
    );
}

1;
