package Fennec::IO::Handle;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
accessors qw/prefix/;

sub TIEHANDLE {
    my $class = shift;
    my ( $prefix ) = @_;

    my $self = bless( \$prefix, $class );

    return $self;
}

sub PRINT {
    my $self = shift;
    require Fennec::IO;
    my $out = Fennec::IO->write_handle;
    my @call = get_test_call();
    local $/ = Fennec::IO->FOS;
    print $out $$self, " $$ $call[0] $call[2]:", @_, $/;
}

sub get_test_call {
    my @stack;
    my $i = 0;
    do { push @stack => [caller($i++)] }
        while $stack[-1]->[0] ne 'Fennec::Runner';

    my $testclass = $stack[-2]->[0];
    my $call;
    do { $call = pop @stack }
        until !@stack || $stack[-1]->[0] ne $testclass;

    return @$call;
}

1;
