package Fennec::FileType;
use strict;
use warnings;

use Carp;
use Fennec::Util::Abstract;
require Fennec;

use Fennec::Util::Alias qw/
    Fennec::FileLoader
/;

use File::Find qw/find/;
BEGIN {
    *_find = \&find;
    undef( *Fennec::FileType::find );
}

Abstract qw/ valid_file load_file paths /;

sub new {
    my $class = shift;
    my ( $file ) = @_;

    croak( "$class\::new() called without a filename" )
        unless $file;
    croak( "$file is not a valid $class file" )
        unless $class->valid_file( $file );

    return bless( [ $file, 0 ], $class );
}

sub load {
    my $self = shift;
    return 1 if $self->[1]++;

    my $tclass = $self->load_file( $self->[0] );

    croak( "loading '" . $self->[0] . "' did not produce a test class" )
        unless $tclass;
    return $tclass;
}

sub filename {
    my $self = shift;
    $self->[0];
}

sub find {
    my $class = shift;
    my @list;
    _find(
        sub {
            my $file = $File::Find::name;
            return unless $class->valid_file( $file );
            push @list => $file;
        },
        map { FileLoader->root . "/$_" } $class->paths
    ) if $class->paths;

    return map { $class->new( $_ ) } @list;
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
