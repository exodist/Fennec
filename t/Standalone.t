#!/usr/bin/perl;
package TEST::Standalone;
use strict;
use warnings;
use Fennec::Standalone asserts => [ 'Core', 'Interceptor' ];

my $res = capture {
    ok( 1, "outside!" );
};
ok( @$res, "Captured res outside" );

tests hello_world_group => sub {
    my $self = shift;
    ok( 1, "Hello world" );
    my $result = capture {
        diag "Hello Message";
    };
    is( $result->[0]->stderr->[0], "Hello Message", "Got diag" );

    my $output = capture {
        ok( 0, "Should fail" );
    };
    ok( !$output->[0]->pass, "intercepted a failed test" );
};

finish;

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
