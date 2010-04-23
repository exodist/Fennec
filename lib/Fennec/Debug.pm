package Fennec::Debug;
use strict;
use warnings;
use Carp qw/cluck/;

sub debug {
    my $class = shift;
    my @messages = @_;
    cluck @messages;
    print $class->collector_state;
    print $class->runner_state;
}

sub collector_state {
    "Not ready";
}

sub runner_state {
    "Not ready";
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
