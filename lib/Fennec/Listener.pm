package Fennec::Listener;
use strict;
use warnings;

use Carp qw/croak/;

sub new        { croak "You must subclass new()in your listener(" . shift(@_) . ")"         }
sub ok         { croak "You must subclass ok() in your listener(" . shift(@_) . ")"         }
sub diag       { croak "You must subclass diag() in your listener(" . shift(@_) . ")"       }
sub skip       { croak "You must subclass skip() in your listener(" . shift(@_) . ")"       }
sub todo_start { croak "You must subclass todo_start() in your listener(" . shift(@_) . ")" }
sub todo_end   { croak "You must subclass todo_end() in your listener(" . shift(@_) . ")"   }
sub terminate  { 1;                                                                         }

1;

__END__

=head1 NAME

Fennec::Listener - Base class for Fennec listeners.

=head1 DESCRIPTION

Override this to create a new listener.

=head1 METHODS TO OVERRIDE

=over 4

=item $class->new()

Create a new instance of the listener, takes no arguments.

=item $obj->ok( $status, $name)

=item $obj->diag( @messages )

=item $obj->skip( $name )

=item $obj->todo_start( $reason )

=item $obj->todo_end()

Sometimes Fennec needs to produce test results, it will turn to the listener to
do so. All 5 of these must be provided.

=item $obj->terminate()

Called when the master process is about to exit.

=back

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
