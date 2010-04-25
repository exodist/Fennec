package Fennec::FileLoader::Module;
use strict;
use warnings;

use base 'Fennec::FileLoader';
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
    my $file = $self->filename;
    require $file;
    return Fennec->_test_class;
}

sub paths { 't/' }

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
