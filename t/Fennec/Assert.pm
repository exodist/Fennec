package TEST::Fennec::Assert;
use strict;
use warnings;

use Fennec asserts => [ 'Core', 'Interceptor' ];

tests require_package => sub {
    require_ok Fennec::Assert;
};

1;
