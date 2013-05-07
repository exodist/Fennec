package Fennec::Listener::TB::Handle;
use strict;
use warnings;

use Fennec::Util qw/accessors get_test_call/;
use Scalar::Util qw/blessed/;

accessors qw/name out/;

sub TIEHANDLE {
    my $class = shift;
    my ($name) = @_;
    return bless( {name => $name}, $class );
}

sub PRINT {
    my $self = shift;
    my @data = @_;
    my @call = get_test_call();
    my $out  = $self->out;

    for my $output (@data) {
        my @serialized = map { join( "\0", $$, $self->name, $call[0], $call[1], $call[2], $_ ) . "\n" } split /[\n\r]+/, $output;

        if ( blessed $out && $out->isa('Fennec::Listener::TB::Collector') ) {
            $out->process($_) for @serialized;
        }
        else {
            print $out @serialized;
        }
    }
}

1;

__END__

=head1 NAME

Fennec::Listener::TB::Handle - The handler used to forward test results to the
reporter process.

=head1 DESCRIPTION

The handler used to forward test results to the reporter process.

=head1 API STABILITY

Fennec versions below 1.000 were considered experimental, and the API was
subject to change. As of version 1.0 the API is considered stabalized. New
versions may add functionality, but not remove or significantly alter existing
functionality.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
