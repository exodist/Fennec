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

util ln => sub {
    my ( $diff ) = @_;
    my ( undef, undef, $line ) = caller;
    return $line + $diff;
};

util result_line_numbers_are => sub {
    my ( $results, @numbers ) = @_;
    result(
        pass => 0,
        name => "result+line counts match",
        stdout => "Number of results, and number of line numbers do not match"
    ) unless @$results == @numbers;

    my $count = 0;
    for my $result ( @$results ) {
        result_line_number_is(
            $result,
            $numbers[$count],
            "Line number for result #$count is " . $numbers[$count]
        );
        $count++;
    }
};

tester 'result_line_number_is';
sub result_line_number_is {
    my ( $result, $number, $name ) = @_;
    my $pass = $number == $result->line ? 1 : 0;
    result(
        pass => $pass,
        name => $name,
        $pass ? () : (stdout => [ "Got: " . $result->line, "Wanted: $number" ]),
    );
};



1;
