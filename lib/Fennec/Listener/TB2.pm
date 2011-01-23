package Fennec::Listener::TB2;
use strict;
use warnings;

use base 'Fennec::Listener::TB';

use Test::Builder2;

my $tb = Test::Builder2->singleton;
$tb->formatter->show_tap_version(0);

1;

__END__

=head1 NAME

Fennec::Listener::TB2 - Listener for Test::Builder2

=head1 DESCRIPTION

This is not yet ready, please do nto use.

=head1 API STABILITY

Fennec versions below 1.000 were considered experimental, and the API was
subject to change. As of version 1.0 the API is considered stabalized. New
versions may add functionality, but not remove or significantly alter existing
functionality.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
