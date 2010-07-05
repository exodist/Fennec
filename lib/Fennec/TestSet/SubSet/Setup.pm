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

sub run_on {
    my $self = shift;
    my ( $on ) = @_;
    return try {
        $self->SUPER::run_on( $on );
        return 1;
    }
    catch {
        die( $_ ) unless m/SKIP:\s*(.*)\s+at/;
        Result->skip_testset( $self, $1 );
        return 0;
    };
}

1;

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
