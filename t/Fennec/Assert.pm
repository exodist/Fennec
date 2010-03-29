package TEST::Fennec::Assert;
use strict;
use warnings;

use Fennec;

tests require_package => sub {
    require_ok Fennec::Assert;
};

1;

__END__
