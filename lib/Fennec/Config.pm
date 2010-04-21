package Fennec::Config;
use strict;
use warnings;

our $CONFIG;

sub defaults {(
    '/etc/fennec/config.pm',
    ($ENV{HOME} || $ENV{USERPROFILE}) . '/.fennec/config.pm',
)}

sub fetch {
    unless ( $CONFIG ) {
        for my $file ( defaults() ) {
            next unless -e $file;
            my $data = do $file;
            next unless $data;
            $CONFIG = { ($CONFIG ? (%$CONFIG) : ()), %$data };
        }
        $CONFIG ||= {};
    }
    return (%$CONFIG);
}

sub reload {
    $CONFIG = undef;
    return (fetch());
}

1;
