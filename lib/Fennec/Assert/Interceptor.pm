package Fennec::Assert::Interceptor;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Runner;
use Fennec::Collector::Interceptor;

util capture => sub(&) {
    my ( $code ) = @_;
    my $collector = Fennec::Collector::Interceptor->new;
    Runner->run_with_collector( $collector, $code );
    return $collector->intercepted;
};

1;
