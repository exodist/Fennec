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
=head1 SYNOPSIS

=head1 METHODS

=head2 new

=head2 handle

=head2 finish

=head2 start

=head2 starting_file

=head2 fennec_error

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
