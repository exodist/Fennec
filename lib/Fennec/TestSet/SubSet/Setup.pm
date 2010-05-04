package Fennec::TestSet::SubSet::Setup;
use strict;
use warnings;

use base 'Fennec::Base::Method';

use Fennec::Util::Accessors;
use Try::Tiny;

use Fennec::Util::Alias qw/
    Fennec::Output::Diag
    Fennec::Output::Result
/;

Accessors qw/testfile/;

sub run {
    my $self = shift;
    return try {
        $self->run_on( $self->testfile );
        return 1;
    }
    catch {
        die( $_ ) unless m/SKIP:\s*(.*)\s+at/;
        Result->skip_testset( $self, $1 );
        return 0;
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
