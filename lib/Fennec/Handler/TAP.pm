package Fennec::Handler::TAP;
use strict;
use warnings;
use Carp;

use base 'Fennec::Handler';
use Fennec::Util::Alias qw/
    Fennec::Runner
    Fennec::FileLoader
/;

use Fennec::Util::Accessors;
Accessors qw/outhandle/;

sub init {
    my $self = shift;

    # Force STDOUT to STDERR unless we generate it
    open my $stdout, ">&STDOUT" or die "Can't duplicate STDOUT: $!";
    close STDOUT;
    open STDOUT, ">&", \*STDERR or die "Can't redirect STDOUT to STDERR";
    $self->outhandle( $stdout );

    $self->{ out_std } ||= sub { print $stdout "$_\n" for @_ };

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

sub handle {
    my $self = shift;
    my ( $item ) = @_;

    unless ( $item ) {
        carp "No item";
        return;
    }

    return $self->result( $item ) if $item->isa( 'Fennec::Output::Result' );

    if ( $item->isa( 'Fennec::Output::Diag' ) || $item->isa( 'Fennec::Output::Note' )) {
        $self->stderr( @{ $item->stderr }) if $item->stderr;
        $self->stdout( @{ $item->stdout }) if $item->stdout;
        return;
    }
    elsif ( $item->isa( 'Fennec::Output::BailOut' )) {
        $self->stderr( @{ $item->stderr }) if $item->stderr;
        $self->_output( 'out_std', "Bail out!" );
        return;
    }

    warn "Unhandled output type: $item";
}

sub starting_file {
    my $self = shift;
    my ( $filename ) = @_;

    my $root = FileLoader->root;
    $filename =~ s|^$root/?||;

    my $n = $self->_file_count;
    my $t = @{ Runner->files };

    $self->_output( 'out_std', "\nStarting file ($n/$t) $filename" );
    $self->_output( 'out_std', '-' x 40 );
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;

    $self->_result_line( $result );
    $self->_result_diag( $result );
}

sub stdout {
    my $self = shift;
    for my $msg ( @_ ) {
        chomp( my $out = $msg );
        $self->_output( 'out_std', "# $out" );
    }
}

sub stderr {
    my $self = shift;
    for my $msg ( @_ ) {
        chomp( my $out = $msg );
        $self->_output( 'out_err', "# $out" );
    }
}

sub finish {
    my $self = shift;
    $self->_output( 'out_std', '1..' . ($self->_test_count - 1));
}

sub fennec_error {
    my $self = shift;
    $self->_output(
        'out_std',
        "not ok " . $self->_test_count . " - Fennec Internal error"
    );
    $self->stderr( $_ ) for ( @_ );
}

sub _test_count {
    my $self = shift;
    $self->{ count } ||= 1;
    my $num = $self->{ count }++;
    sprintf( "%.4d", $num );
}

sub _file_count {
    my $self = shift;
    $self->{ fcount } ||= 1;
    return $self->{ fcount }++;
}

sub _output {
    my $self = shift;
    my $type = shift;
    $self->{ $type }->( @_ );
}

sub _benchmark {
    my $self = shift;
    my ( $bma ) = @_;
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
        else { # ( $bm < 100 )
            $template = '[%2.3f]';
        }
    }

    return sprintf( $template, $bm );
}

sub _status {
    my $self = shift;
    my ( $result ) = @_;
    return ($result->pass || $result->skip) ? 'ok' : 'not ok';
}

sub _postfix {
    my $self = shift;
    my ( $result ) = @_;

    if ( my $todo = $result->todo ) {
        return "# TODO $todo";
    }
    elsif ( my $skip = $result->skip ) {
        return "# SKIP $skip";
    }

    return "";
}

sub _result_line {
    my $self = shift;
    my ( $result ) = @_;

    my $status = $self->_status( $result );
    my $count = $self->_test_count;
    my $benchmark = $self->_benchmark( $result->benchmark );
    my $name = $result->name || "[UNNAMED TEST]";
    my $postfix = $self->_postfix( $result );
    my $out = join( ' ', $status, $count, $benchmark, '-', $name, $postfix );

    $self->_output( 'out_std', $out );
}

sub _result_diag {
    my $self = shift;
    my ( $result ) = @_;

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

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
