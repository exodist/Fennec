package Fennec::Collector::TempFiles;
use strict;
use warnings;

use base 'Fennec::Collector';

use File::Temp;

use Fennec::Util qw/ accessors /;

accessors qw/tempdir handles/;

sub validate_env { 1 }

sub new {
    my $class = shift;

    my $temp = File::Temp->newdir( CLEANUP => 0 );
    print STDERR "# Using temp dir: '$temp' for process results\n";

    return bless {
        tempdir => "$temp",
        handles => {},
    }, $class;
}

sub report {
    my $self   = shift;
    my %params = @_;

    my $handle;
    if ( $self->handles->{$$} ) {
        $handle = $self->handles->{$$};
    }
    else {
        my $path = $self->tempdir . "/$$";
        open( $handle, '>', $path ) || die "$!";
        $self->handles->{$$} = $handle;
    }

    for my $item ( @{$params{data}} ) {
        for my $part ( split /\r?\n/, $item ) {
            print $handle "$params{name}|$params{source}|$part\n";
        }
    }
}

sub collect {
    my $self = shift;

    my $handle;
    if ( $self->handles->{tempdir} ) {
        $handle = $self->handles->{tempdir};
        rewinddir $handle;
    }
    else {
        opendir( $handle, $self->tempdir ) || die "$!";
        $self->handles->{tempdir} = $handle;
    }

    while ( my $file = readdir $handle ) {
        my $path = $self->tempdir . "/$file";
        next unless -f $path;
        next unless $path =~ m/\.ready$/;
        open( my $fh, '<', $path ) || die $!;

        while ( my $line = <$fh> ) {
            chomp($line);
            next unless $line;
            my ( $handle, $source, $part ) = ( $line =~ m/^(\w+)\|([^\|]+)\|(.*)$/g );
            warn "Bad Input: '$line'\n" unless $handle && $source;

            $self->inc_test_count
                if $handle eq 'STDOUT'
                && $part =~ m/^\s*(not\s+)?ok(\s|$)/;

            if ( $ENV{HARNESS_IS_VERBOSE} || $handle eq 'STDOUT' ) {
                print STDOUT "$part\n";
            }
            else {
                print STDERR "$part\n";
            }
        }

        close($fh);

        rename( $path => "$path.done" ) || die "Could not rename file: $!";
    }
}

sub finish {
    my $self = shift;

    $self->ready() if $self->handles->{$$};

    $self->collect;
    $self->SUPER::finish();

    my $handle = $self->handles->{tempdir};
    rewinddir $handle;

    die "($$) Not all files were collected?!"
        if grep { m/^\d+(\.ready)?$/ } readdir $handle;
}

sub ready {
    my $self = shift;
    warn "No Temp Dir! $$" unless $self->tempdir;
    my $path = $self->tempdir . "/$$";
    return unless -e $path;
    close( $self->handles->{$$} ) || warn "Could not close file $path - $!";
    rename( $path => "$path.ready" ) || warn "Could not rename file $path - $!";
}

sub DESTROY {
    my $self = shift;
    $self->ready;
}

1;
