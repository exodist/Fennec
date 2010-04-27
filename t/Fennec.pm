package TEST::Fennec;
use strict;
use warnings;

use Fennec;

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

tests error_tests => sub {
    my ( $fail, $err );
    {
        no warnings 'once';
        local $Fennec::Runner::SINGLETON = undef;
        $fail = !eval( 'package FAKEPACKAGE; use Fennec; 1' );
        $err = $@ if $fail;
    }
    ok( $fail, "Failed w/o runner" );
    like( $err, qr/Test runner not found/, "Proper error" );

    ok( !eval 'package main; use Fennec; 1', "Fail in main" );
    like( $@, qr/You must put your tests into a package, not main/, "Proper error" );

    throws_ok { Fennec::_export_package_to( 'FAKEPACKAGE' )}
        qr/Can't locate FAKEPACKAGE\.pm in \@INC/,
        "Cannot export from invalid package";
};

tests exports => sub {
    warning_like { done_testing }
     qr/calling done_testing\(\) is only required for Fennec::Standalone tests/,
     "done_testing in standalone only";

    throws_ok { use_or_skip XXX::Fake::Package }
        qr/SKIP: XXX::Fake::Package is not installed or insufficient version:/,
        "use_or_skip";

    throws_ok { use_or_skip XXX::Fake::Package, 'a', 'b', 'c' }
        qr/SKIP: XXX::Fake::Package is not installed or insufficient version:/,
        "use_or_skip";

    throws_ok { use_or_skip Fennec, 100000 }
        qr/SKIP: Fennec is not installed or insufficient version: Fennec version 100000 required/,
        "use_or_skip w/ version";

    throws_ok { require_or_skip XXX::Fake::Package }
        qr/SKIP: XXX::Fake::Package is not installed/,
        "require_or_skip";
};

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
