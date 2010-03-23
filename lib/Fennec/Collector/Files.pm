package Fennec::Collector::Files;
use strict;
use warnings;

use base 'Fennec::Collector';

use Fennec::Runner;
use Data::Dumper;

our %BADFILES;
our $SEMI_UNIQ = 1;

sub bad_files { \%BADFILES }

sub cull {
    my $self = shift;
    my $handle = $self->dirhandle;
    for my $file ( readdir( $handle )) {
        next if -d $file;
        next if $file =~ m/^\.+$/;
        my ($obj) = $self->read_and_unlink( $file );
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
    $self->SUPER::finish(@_);
    my $handle = $self->{ dirhandle };
    close( $handle );
}

sub read_and_unlink {
    my $class = shift;
    my @out;
    for my $file ( @_ ) {
        next if $BADFILES{ $file };
        if( my $obj = $class->read( $file )) {
            push @out => $obj;
            unlink( Runner->testdir . "/$file" );
        }
    }
    return @out;
}

sub read {
    my $class = shift;
    my ( $file ) = @_;
    my $obj = do( Runner->testdir . "/$file" );
    if ( $obj ) {
        my $bless = $obj->{ bless };
        my $data = $obj->{ data };
        return bless( $data, $bless );
    }
    warn( "bad file: '$file' - $! - $@" );
    $BADFILES{$file} = [ $!, $@ ];
    return;
}

sub write {
    my $self = shift;
    my ( $output ) = @_;
    my $out = $output->serialize;
    my $file = Runner->testdir . "/$$-$output-" . $SEMI_UNIQ++;
    open( my $HANDLE, '>', $file ) || warn "Error writing output:\n\t$file\n\t$!";
    print $HANDLE Dumper( $out ) || warn "Error writing output";
    close( $HANDLE ) || die( $! );
}

1;
