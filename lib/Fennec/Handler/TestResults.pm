package Fennec::Handler::TestResults;
use strict;
use warnings;

require Fennec::Tester::TestResults;
use base 'Fennec::Handler';

sub init {
    my $self = shift;
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;
    Fennec::Tester::TestResults::_push_results( $result );
    $self->diag( @{ $result->diag }) if $result->diag;
}

sub diag {
    my $self = shift;
    Fennec::Tester::TestResults::_push_diag( @_ );
}

sub finish {
    my $self = shift;
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
