package Fennec::TestSet::SubSet::Setup;
use strict;
use warnings;

use base 'Fennec::Base::Method';

use Fennec::Util::Accessors;
use Try::Tiny;

use Fennec::Util::Alias qw/
    Fennec::Output::Diag
/;

Accessors qw/testfile/;

sub lines_for_filter {
    my $self = shift;
    B::svref_2object( $self->method )->START->line;
}

sub run {
    my $self = shift;
    try {
        $self->run_on( $self->testfile );
    }
    catch {
        Diag->new( stdout => [ $self->name . " error: $_" ])->write
    };
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
