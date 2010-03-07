package Fennec::Consumer;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %proto = @_;
    my $self = bless( \%proto, $class );
    $self->init if $self->can( 'init' );
    return $self;
}

sub result {
    my $class = shift;
    die( "$class does not implement result()" );
}

sub diag {
    my $class = shift;
    die( "$class does not implement diag()" );
}

sub finish {1}

1;

=head1 NAME

Fennec::Consumer - Base class for output plugins

=head1 DESCRIPTION

Output plugins should inherit and override this class.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
