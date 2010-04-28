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

    unless ( $self->[1] ) {
        $self->[1] = $self->load_file( $self->[0] );
    }

    croak( "loading '" . $self->[0] . "' did not produce a test class" )
        unless $self->[1];

    return $self->[1];
}

sub filename {
    my $self = shift;
    $self->[0];
}

sub find {
    my $class = shift;
    my @list;
    _find(
        {
            follow => 1,
            wanted => sub {
                my $file = $File::Find::name;
                return unless $class->valid_file( $file );
                push @list => $file;
            },
        },
        map { FileLoader->root . "/$_" } $class->paths
    ) if $class->paths;

    return map { $class->new( $_ ) } @list;
}

1;

=head1 NAME

Fennec::FileType - Base class for FileType plugins.

=head1 DESCRIPTION

All FileType plugins for fennec should subclass this module.

=head1 ABSTRACT METHODS

Your FileType must override these

=over 4

=item $bool = $class->valid_file( $filename )

Check if a file is of this type.

=item $testfile_class = $obj->load_file()

Load the file the object was constructed with and return the testfile class it
produced.

=item @paths = paths()

Should return a list of paths relative to project root which contain test
files.

=back

=head1 CONSTRUCTOR

=over

=item $obj = $class->new( $filename )

Creates an instance of your filetype object.

=back

=head1 CLASS METHODS

=over 4

=item @testfiles = $class->find()

Find all the TestFiles in a project that are of this FileType.

=back

=head1 OBJECT METHODS

=over 4

=item $obj->filename()

Get the filename this instance was constructed with.

=item $testfile_class = $obj->load()

Load the FileType object and return the class name of the TestFile class it
produced.

Only loads the file once.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
