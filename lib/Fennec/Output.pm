package Fennec::Output;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Util::Abstract;
use Fennec::File;
use Fennec::Runner;
use Data::Dumper;

our %BADFILES;
our $SEMI_UNIQ = 1;

Accessors qw/ stdout stderr workflow /;

sub bad_files { \%BADFILES }

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
    my $out = $self->serialize;
    $out->{ data }->{ workflow_stack } = $self->workflow_stack;
    my $file = Runner->testdir . "/$$-$self-" . $SEMI_UNIQ++;
    open( my $HANDLE, '>', $file ) || warn "Error writing output:\n\t$file\n\t$!";
    print $HANDLE Dumper( $out ) || warn "Error writing output";
    close( $HANDLE ) || die( $! );
}

sub workflow_stack {
    my $self = shift;
    unless ( $self->{ workflow_stack }) {
        my $current = $self->workflow;
        return undef unless $current;
        my @out = ( $current->name );
        while ( $current = $current->parent && $current->isa( 'Fennec::Workflow' )) {
            push @out => $current->name;
        }
        $self->{ workflow_stack } = [ reverse @out ];
    }
    return $self->{ workflow_stack };
}

sub serialize {
    my $self = shift;
    return {
        data => { %$self, workflow => undef },
        bless => ref( $self ),
    };
}

1;
