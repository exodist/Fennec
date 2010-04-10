package TEST::Fennec::Assert::Core::Warn;
use strict;
use warnings;

use Fennec;
use Fennec::Assert::Interceptor;

our $CLASS = 'Fennec::Assert::Core::Warn';

tests 'warning is' => sub {
    warning_is {
        warn 'apple'
    } 'apple at ' . __FILE__ . ' line ' . ln(-1) . ".\n", "warning_is()";
};

1;
