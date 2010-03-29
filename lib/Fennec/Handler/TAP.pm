package Fennec::Handler::TAP;
use strict;
use warnings;
use Carp;

use base 'Fennec::Handler';

sub init {
    my $self = shift;
    $self->{ out_std } ||= sub { print STDOUT "$_\n" for @_ };
    $self->{ out_err } ||= sub { print STDERR "$_\n" for @_ };
}

sub count {
    my $self = shift;
    $self->{ count } ||= 1;
    my $num = $self->{ count }++;
    sprintf( "%.4d", $num );
}

sub output {
    my $self = shift;
    my $type = shift;
    $self->{ $type }->( @_ );
}

sub handle {
    my $self = shift;
    my ( $item ) = @_;
    unless ( $item ) {
        carp "No item";
        return;
    }
    return $self->result( $item ) if $item->isa( 'Fennec::Output::Result' );
    return $self->stdout( @{ $item->stdout }) if $item->isa( 'Fennec::Output::Diag' );
    warn "Unhandled output type: $item";
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;

    my $out = (($result->pass || $result->skip) ? 'ok ' : 'not ok ' ) . $self->count . " -";
    $out .= $result->benchmark ? sprintf( " [%7.2f]", $result->benchmark->[0])
                               : " [  N/A  ]";
    $out .= " " . $result->name if $result->name;
    if ( my $todo = $result->todo ) {
        $out .= " # TODO $todo";
    }
    elsif ( my $skip = $result->skip ) {
        $out .= " # SKIP $skip";
    }
    $self->output( 'out_std', $out );
    if ( $result->fail && !$result->todo && !$result->skip ) {
        if ( $result->file ) {
            my $error = "Test failure at " . $result->file;
            $error .= " line " . $result->line if $result->line;
            $self->stdout( $error );
        }
        $self->stderr( "Workflow Stack: " . join( ', ', @{ $result->workflow_stack }))
            if $result->workflow_stack;
    }
    my $stdout = $result->stdout;
    return unless $stdout;
    $self->stdout( $_ ) for @$stdout
}

sub stdout {
    my $self = shift;
    for my $msg ( @_ ) {
        chomp( my $out = $msg );
        $self->output( 'out_std', "# $out" );
    }
}

sub stderr {
    my $self = shift;
    for my $msg ( @_ ) {
        chomp( my $out = $msg );
        $self->output( 'out_err', "# $out" );
    }
}

sub finish {
    my $self = shift;
    $self->output( 'out_std', '1..' . ($self->count - 1));
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
