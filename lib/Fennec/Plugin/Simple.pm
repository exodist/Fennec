package Fennec::Plugin::Simple;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Fennec::Plugin::Simple - L<Test::Simple> functionality.

=head1 DESCRIPTION

This provides the ok() function.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 TESTER FUNCTIONS

=over 4

=item ok( $result )

=item ok( $result, $name )

Test passes if $result is true, otherwise it fails.

=cut

#}}}

use Fennec::Plugin;

tester ok => (
    min_args => 1,
    max_args => 2,
    code => sub {
        my ( $result, $name ) = @_;
        return ( $result ? 1 : 0, $name );
    },
);

1;

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
