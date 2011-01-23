package Fennec::Listener::TB2;
use strict;
use warnings;

use base 'Fennec::Listener';
use Fennec::Util;

die "Fennec Does not yet support Test::Builder2 as TB2 is itself incomplete.";

sub new {}
sub terminate {}

sub ok         { shift; Fennec::Util::tb2_ok( @_ )        }
sub diag       { shift; Fennec::Util::tb2_diag( @_ )      }
sub skip       { shift; Fennec::Util::tb2_skip( @_ )      }
sub todo_start { shift; Fennec::Util::tb2_todo_start( @_ )}
sub todo_end   { shift; Fennec::Util::tb2_todo_end( @_ )  }

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
