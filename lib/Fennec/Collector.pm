package Fennec::Collector;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Runner;
use Fennec::Output;
use Fennec::Util::Accessors;

Accessors qw/handlers/;

sub new {
    my $class = shift;
    my @handlers;
    for my $hclass ( @_ ) {
        $hclass = 'Fennec::Handler::' . $hclass;
        eval "require $hclass; 1" || die ( @_ );
        push @handlers => $hclass->new();
    }
    return bless( { handlers => \@handlers }, $class );
}

sub start {
    my $self = shift;
    print "Start\n";
    $_->start for @{ $self->handlers };
}

sub cull {
    my $self = shift;
    print "Cull\n";
    my $handle = $self->dirhandle;
    for my $file ( readdir( $handle )) {
        next if -d $file;
        next if $file =~ m/^\.+$/;
        my ($obj) = Output->read_and_unlink( $file );
        $_->handle( $obj ) for @{ $self->handlers };
    }
}

sub dirhandle {
    my $self = shift;
    unless( $self->{ dirhandle }) {
        my $path = Runner->testdir;
        opendir( my $handle, $path ) || die( "Cannot open dir $path: $!" );
        $self->{ dirhandle } = $handle;
    }

    return $self->{ dirhandle };
}

sub finish {
    my $self = shift;
    $self->cull;
    print "Finish\n";
    $_->finish for @{ $self->handlers };
    my $handle = $self->{ dirhandle };
    close( $handle );
}

1;
