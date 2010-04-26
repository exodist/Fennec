package Fennec::FileType::Module;
use strict;
use warnings;

use base 'Fennec::FileType';

use Fennec::Util::Alias qw/
    Fennec
/;

sub valid_file {
    my $class = shift;
    my ( $file ) = @_;
    return $file =~ m{/t/.*\.pm$} ? 1 : 0;
}

sub load_file {
    my $self = shift;
    Fennec->_clear_test_class;
    my $file = $self->filename;
    require $file;
    return Fennec->_test_class;
}

sub paths { 't/' }

1;

=head1 NAME

Fennec::FileType::Module - Load module files under t/ as test files.

=head1 DESCRIPTION

Finds all .pm objects under the t/ directory and uses them as test files.

=head1 METHODS

This class inherits from L<Fennec::FileType>.

=over 4

=item $bool = $class->valid_file( $filename )

Check if a file is a valid test file of this type.

=item $test_class = $obj->load_file()

Load the testfile this instance was built with. Return the class for the
testfile.

=item @paths = $class->paths()

Returns a list of paths in which to search for test files.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
