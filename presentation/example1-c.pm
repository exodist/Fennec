package TEST::MyModule;
use strict;
use warnings;
use Fennec;

use_ok( 'MyModule' );

sub init {
    my $self = shift;
    ...;
}

tests Sanity => sub {
    my $self = shift;
    can_ok( 'MyModule', qw/a b/ );
    isa_ok( 'MyModule', 'OtherModule' );
};

tests 'Check defaults' => sub {
    my $one = MyModule->new;
    is( MyModule->a, 'a', "defualt for a" );
    is( MyModule->b, 'b', "defualt for b" );
};

tests 'Set values' => sub {
    my $one = MyModule->new( a => 'A', b => 'B' );
    is( MyModule->a, 'A', "construct value a" );
    is( MyModule->b, 'B', "construct value b" );
};

1;
