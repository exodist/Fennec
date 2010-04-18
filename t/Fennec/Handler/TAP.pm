package TEST::Fennec::Handler::TAP;
use strict;
use warnings;

use Fennec;
use Fennec::Util::Alias qw/
    Fennec::Output::Result
    Fennec::Output::Diag
/;

our $CLASS = 'Fennec::Handler::TAP';
use_ok $CLASS;

tests 'create' => sub {
    my $one = $CLASS->new( out_std => sub {}, out_err => sub {} );
    isa_ok( $one, $CLASS );
    can_ok( $one, qw/handle fennec_error finish/ );
};

tests 'verbose' => sub {
    local $ENV{HARNESS_ACTIVE} = 1;
    local $ENV{HARNESS_IS_VERBOSE} = 1;
    my $one = $CLASS->new( out_std => sub {} );
    is( $one->{ out_err }, $one->{ out_std }, "verbose sends err to std" );

    local $ENV{HARNESS_ACTIVE} = 0;
    local $ENV{HARNESS_IS_VERBOSE} = 0;
    $one = $CLASS->new( out_std => sub {} );
    is( $one->{ out_err }, $one->{ out_std }, "no harness - send err to std" );
};

tests 'verbose' => sub {
    local $ENV{HARNESS_ACTIVE} = 1;
    local $ENV{HARNESS_IS_VERBOSE} = 0;
    my $one = $CLASS->new( out_std => sub {} );
    isnt( $one->{ out_err }, $one->{ out_std }, "non-verbose sends err to err" );
};

tests 'count' => sub {
    my $one = $CLASS->new( out_std => sub {}, out_err => sub {} );
    is( $one->_count, "0001", "First count" );
    is( $one->_count, "0002", "Increment" );
    is( $one->_count, "0003", "Increment again" );
};

tests 'handle' => sub {
    my ( @err, @out );
    my $one = $CLASS->new(
        out_std => sub { @out = @_ },
        out_err => sub { @err = @_ },
    );
    $one->handle( Result->new( pass => 1 ));
    is( @out, 1, "Result output in out" );
    $one->handle( Result->new( pass => 0 ));
    is( @out, 1, "Result output" );

    $one->handle( Diag->new( stderr => [ "a" ]));
    is( @err, 1, "diag message" );
    is( $err[0], "# a", "Got message" );

    warning_is { $one->handle( Diag->new( stdout => [ "a" ]))}
        "Diag with stdout is deprecated\n",
        "deprecate diag stdout";

    warning_like { $one->handle( bless( {}, 'XXX' ))}
        qr/Unhandled output type: XXX=HASH/,
        "Unhandled output";

    warning_like { $one->handle }
        qr/No item at/,
        "No item warning";
};

tests result => sub {
    # Put tests in coderef, localize subs, run tests.
    my ( $line, $diag ) = ( 0,0 );
    my $run = sub {
        my $one = $CLASS->new( out_std => sub {1}, out_err => sub {1} );
        $one->result();
        ok( !$line && !$diag, "Nothing w/o a result" );
        $one->result( 1 );
        is( $line, 1, "Generate a line" );
        is( $diag, 1, "Diag" );
    };
    no strict 'refs';
    no warnings 'redefine';
    local *{ $CLASS . '::_result_line' } = sub { $line++ };
    local *{ $CLASS . '::_result_diag' } = sub { $diag++ };
    $run->();
};

tests 'output' => sub {
    my ( $err, $out );
    my $one = $CLASS->new( out_std => sub { ($out) = @_ }, out_err => sub { ($err) = @_ });
    $one->_output( 'out_std', "hi" );
    $one->_output( 'out_err', "bye" );
    is( $out, 'hi', "Send std" );
    is( $err, 'bye', "Send err" );

    $one->stdout( 'a' );
    is( $out, '# a', "stdout" );

    $one->stderr( 'a' );
    is( $err, '# a', "stderr" );
};

tests 'finish' => sub {
    my ( $out );
    my $one = $CLASS->new( out_std => sub { ($out) = @_ }, out_err => sub {1});
    $one->_count for 1 .. 5;
    $one->finish;
    is( $out, '1..5', "Test count" );

};

1;

__END__

sub fennec_error {
    my $self = shift;
    for my $msg ( @_ ) {
        my $out = "not ok " . $self->_count . " - Fennec Internal error";
        $self->stdout( $out );
        $self->stderr( $msg );
    }
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
        elsif ( $bm < 100 ) {
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
    my $count = $self->_count;
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
