#!/usr/bin/perl;
package TEST::MyModule;
use strict;
use warnings;
use Fennec::Standalone;

use_ok( 'MyModule' );

# Sanity
can_ok( 'MyModule', qw/a b/ );
isa_ok( 'MyModule', 'OtherModule' );

#Check defaults
my $one = MyModule->new;
is( MyModule->a, 'a', "defualt for a" );
is( MyModule->b, 'b', "defualt for b" );

#Set values
my $two = MyModule->new( a => 'A', b => 'B' );
is( MyModule->a, 'A', "construct value a" );
is( MyModule->b, 'B', "construct value b" );

done_testing;

1;
