package Fennec::Util;
use strict;
use warnings;

use base 'Fennec::Base';

sub package_subs {
    my ( $package, $match ) = @_;
    $package = $package . '::';
    no strict 'refs';
    my @list = grep { defined( *{$package . $_}{CODE} )} keys %$package;
    return @list unless $match;
    return grep { $_ =~ $match } @list;
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
