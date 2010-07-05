package Fennec::Util::Sub;
use strict;
use warnings;

use B;

sub new {
    my $class = shift;
    return bless( [@_], $class );
}

sub coderef { return \&{ shift->[0]} }

sub end_line {
    my $self = shift;
    return undef unless $self->is_anon;
    return $self->[1] || undef;
}

sub start_line {
    my $self = shift;
    my $from_b = B::svref_2object(
        $self->coderef
    )->START->line;
    my $end_line = $self->end_line;
    return ($from_b - 1) if !$end_line || $end_line > $from_b;
    return $from_b;
}

sub name {
    my $self = shift;
    return B::svref_2object(
        $self->coderef
    )->GV->NAME;
}

sub is_anon {
    my $self = shift;
    return $self->name eq '__ANON__' ? 1 : 0;
}

sub package {
    my $self = shift;
    return B::svref_2object(
        $self->coderef
    )->GV->STASH->NAME;
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
