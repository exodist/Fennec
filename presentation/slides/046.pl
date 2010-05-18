




package TEST::MyTest;
use strict;
use warnings;
use Fennec;

describe 'my group' {
    my $self = shift;

    before_each { $self->load_data }
    after_each { $self->unload_data }

    # it is an alias to 'tests'
    it 'my test' {
        my $self = shift;
        ok( 1, 'spec test!' );
    }

    # Nested!
    describe ...;
}

1;







