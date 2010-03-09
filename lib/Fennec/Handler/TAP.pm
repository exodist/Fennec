package Fennec::Handler::TAP;
use strict;
use warnings;
use Carp qw/confess/;

use base 'Fennec::Handler';

sub init {
    my $self = shift;
    $self->{ output } ||= sub { print "$_\n" for @_ };
}

sub count {
    my $self = shift;
    $self->{ count } ||= 1;
    my $num = $self->{ count }++;
    sprintf( "%.4d", $num );
}

sub output {
    my $self = shift;
    $self->{ output }->( @_ );
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;
    my $out = ($result->result || $result->skip ? 'ok ' : 'not ok ' ) . $self->count . " -";
    $out .= $result->benchmark ? sprintf( " [%7.2f]", $result->benchmark->[0])
                               : " [  N/A  ]";
    $out .= " " . $result->name if $result->name;
    if ( my $todo = $result->todo ) {
        $out .= " # TODO $todo";
    }
    elsif ( my $skip = $result->skip ) {
        $out .= " # SKIP $skip";
    }
    $self->output( $out );
    if ( !$result->result && !$result->todo && !$result->skip ) {
        my $case = $result->case ? $result->case->name : 'N/A';
        my $set = $result->set ? $result->set->name : 'N/A';
        $self->diag( "Test failure at " . $result->file . " line " . $result->line );
        $self->diag( "    case: $case", "    set: $set" );
    }
    my $diag = $result->diag;
    return unless $diag;
    $self->diag( $_ ) for @$diag
}

sub diag {
    my $self = shift;
    for my $msg ( @_ ) {
        chomp( my $out = $msg );
        $self->output( "# $out" );
    }
}

sub finish {
    my $self = shift;
    $self->output( '1..' . ($self->count - 1));
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
