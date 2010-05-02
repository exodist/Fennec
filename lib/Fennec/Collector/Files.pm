package Fennec::Collector::Files;
use strict;
use warnings;

use base 'Fennec::Collector';

BEGIN {
    my $pid = $$;
    my $old = $SIG{INT};
    $SIG{INT} = sub {
        __PACKAGE__->_cleanup if $$ == $pid;
        $old->() if $old;
        exit 1;
    };
}

use Fennec::Util::Alias qw/
    Fennec::Runner
    Fennec::Output
/;

use Fennec::FileLoader;
use Data::Dumper;
use File::Temp qw/tempdir/;

our %BADFILES;
our $SEMI_UNIQ = 1;
our $TEMPDIR;
our $PID = $$;

sub _bad_files { \%BADFILES }

sub cull {
    my $self = shift;
    my $handle = $self->_dirhandle;
    my @objs;

    for my $file ( readdir( $handle )) {
        next if -d $file;
        next if $file =~ m/^\.+$/;
        next unless $file =~ m/\.res$/;
        next if _bad_files->{ $file };

        my ($obj) = $self->_read_and_unlink( $file );
        unless( $obj ) {
            $_->fennec_error( "Error processing file: $file" )
                for @{ $self->handlers };
            next;
        }
        push @objs => $obj;
    }
    close( $handle );
    return @objs;
}

sub write {
    my $self = shift;
    my ( $output ) = @_;

    my $out = $output->serialize;
    my $file = $self->testdir . "/$$-" . $SEMI_UNIQ++;

    open( my $HANDLE, '>', $file ) || warn "Error writing output:\n\t$file\n\t$!";
    print $HANDLE Dumper( $out ) || warn "Error writing output";
    close( $HANDLE ) || die( $! );

    # Rename file to .res after creation, that way collector does not cull it
    # until it is finished writing.
    rename ( $file, "$file.res" );
}

sub start {
    my $self = shift;
    $self->SUPER::start(@_);
    $self->_prepare;
}

sub finish {
    my $self = shift;
    $self->SUPER::finish(@_);
    $self->_cleanup;
}

sub testdir {
    unless ( $TEMPDIR ) {
        $TEMPDIR = tempdir( Fennec::FileLoader->root . "/_$$\_test_XXXX" );
    }
    return $TEMPDIR;
}

sub _read {
    my $self = shift;
    my ( $file ) = @_;
    my $obj = do( $self->testdir . "/$file" );

    return Output->deserialize( $obj )
        if $obj;

    _bad_files->{$file} = [ $!, $@ ];
    $_->fennec_error( "bad file: '$file' - $! - $@" )
        for @{ $self->handlers };
    return;
}

sub _dirhandle {
    my $self = shift;
    my $path = $self->testdir;
    opendir( my $handle, $path ) || die( "Cannot open dir $path: $!" );
    return $handle;
}

sub _read_and_unlink {
    my $self = shift;
    my @out;

    for my $file ( @_ ) {
        next if _bad_files->{ $file };
        if( my $obj = $self->_read( $file )) {
            push @out => $obj;
            unlink( $self->testdir . "/$file" );
        }
    }

    return @out;
}

sub _prepare {
    my $self = shift;
    $self->_cleanup;
    my $path = $self->testdir;
    mkdir( $path ) unless -d $path;
}

sub _cleanup {
    my $class = shift;
    return unless -d $class->testdir;

    opendir( my $TDIR, $class->testdir ) || die( $! );
    for my $file ( readdir( $TDIR )) {
        next if $file =~ m/^\.+$/;
        next if -d $class->testdir . "/$file";
        unlink( $class->testdir . "/$file" );
    }
    closedir( $TDIR );

    rmdir( $class->testdir ) || warn( "Cannot cleanup test dir: $!" );
}

sub DESTROY {
    my $self = shift;
    $self->_cleanup if $$ == $PID;
}

END { __PACKAGE__->_cleanup if $$ == $PID }

1;

=head1 NAME

Fennec::Collector::Files - File based output collector for fennec

=head1 DESCRIPTION

This is the default collector for fennec. This collector creates a temporary
directory to which it writes all output objects. These files are removed as
they are collected. When the tests complete the temp dir will be removed.

=head1 METHODS

=over 4

=item @outputs = $obj->cull()

Retrieve all the output objects that have been written since the start or last
cull.

=item $obj->write( $output )

Store an output object so that it will be picked up in the parent process.

=item $obj->start()

Start the collector (does preparation work)

=item $obj->finish()

Finish the collector (Cleanup)

=item $dir = $obj->testdir()

Name of the tempdir that stores result files.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
