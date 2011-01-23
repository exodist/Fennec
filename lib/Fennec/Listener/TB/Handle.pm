package Fennec::Listener::TB::Handle;
use strict;
use warnings;

use Fennec::Util qw/accessors get_test_call/;

accessors qw/name out/;

sub TIEHANDLE {
    my $class = shift;
    my ( $name, $out ) = @_;
    return bless( { name => $name, out => $out }, $class );
}

sub PRINT {
    my $self = shift;
    my @data = @_;
    my @call = get_test_call();
    my $out  = $self->out;

    for my $output ( @_ ) {
        print $out join( "\0", $$, $self->name, $call[0], $call[1], $call[2], $_ ) . "\n"
            for split( /[\n\r]+/, $output );
    }
}

1;
__END__

    my $original_print = Test::Builder->can('_print_to_fh');
    *Test::Builder::_print_to_fh = sub {
        my( $tb, $fh, @msgs ) = @_;

        my ( $handle, $output );
        open( $handle, '>', \$output );
        $original_print->( $tb, $handle, @msgs );
        close( $handle );

        my $ohandle = ($fh == $tb->output) ? 'STDOUT' : 'STDERR';

        my @call = get_test_call();
        print $out join( "\0", $$, $ohandle, $call[0], $call[1], $call[2], $_ ) . "\n"
            for split( /[\n\r]+/, $output );
    };

