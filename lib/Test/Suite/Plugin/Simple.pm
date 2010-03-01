package Test::Suite::Plugin::Simple;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Test::Suite::Plugin::Simple - L<Test::Simple> functionality.

=head1 DESCRIPTION

This provides the ok() function.

=head1 EARLY VERSION WARNING

This is VERY early version. Test::Suite does not run yet.

Please go to L<http://github.com/exodist/Test-Suite> to see the latest and
greatest.

=head1 TESTER FUNCTIONS

=over 4

=item ok( $result )

=item ok( $result, $name )

Test passes if $result is true, otherwise it fails.

=cut

#}}}

use Test::Suite::Plugin;

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

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
