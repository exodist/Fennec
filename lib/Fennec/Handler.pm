package Fennec::Handler;
use strict;
use warnings;
use Carp qw/cluck/;

sub new {
    my $class = shift;
    my %proto = @_;
    my $self = bless( \%proto, $class );
    $self->init if $self->can( 'init' );
    return $self;
}

sub handle {
    my $in = shift;
    my $class = ref( $in ) || $in;
    die( "$class does not implement result()" );
}

sub finish {1}
sub start {1}
sub starting_file {1}
sub fennec_error {1}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
