package Fennec::Handler::TAP;
use strict;
use warnings;
use Carp;

use base 'Fennec::Handler';

sub init {
    my $self = shift;

    $self->{ out_std } ||= sub { print STDOUT "$_\n" for @_ };

    my $harness = $ENV{HARNESS_ACTIVE};
    my $verbose = $ENV{HARNESS_IS_VERBOSE};
    # If we have a non-verbose harness then output the errors to STDERR so that
    # they are seen. Outside of a harness, or in verbose mode the error output
    # is sent to STDOUT so that the error message appear at or near the result
    # that generated them.
    if ( $harness && !$verbose ) {
        $self->{ out_err } ||= sub { print STDERR "$_\n" for @_ };
    }
    else {
        $self->{ out_err } ||= $self->{ out_std };
    }
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
    if ( $item->isa( 'Fennec::Output::Diag' )) {
        $self->stderr( @{ $item->stderr }) if $item->stderr;
        if ( $item->stdout ) {
            $self->stdout( @{ $item->stdout });
            warn "Diag with stdout is deprecated\n";
        }
        return;
    }
    warn "Unhandled output type: $item";
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;

    my $out = (($result->pass || $result->skip) ? 'ok ' : 'not ok ' ) . $self->count . " -";
    my $bma = $result->benchmark;
    my $bm = $bma ? $bma->[0] : "N/A  ";
    my $template = '[% 6s]';

    # If we got a number (including -e notation)
    if ( $bm =~ m/^[\d\.e\-]+$/ ) {
        if ( $bm >= 100 ) {
            $bm = int( $bm );
            $template = '[%06s]';
        }
        elsif ($bm < 10) {
            $template = '[%1.4f]';
        }
        elsif ( $bm < 100 ) {
            $template = '[%2.3f]';
        }
    }

    $out .= sprintf( " $template", $bm );

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
            $self->stderr( $error );
        }
        $self->stderr( "Workflow Stack: " . join( ', ', @{ $result->workflow_stack }))
            if $result->workflow_stack;
    }
    if( my $stdout = $result->stdout ) {
        $self->stdout( $_ ) for @$stdout;
    }
    if( my $stderr = $result->stderr ) {
        $self->stderr( $_ ) for @$stderr;
    }
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

sub fennec_error {
    my $self = shift;
    for my $msg ( @_ ) {
        my $out = "not ok " . $self->count . " - Fennec Internal error";
        $self->stdout( $out );
        $self->stderr( $msg );
    }
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
