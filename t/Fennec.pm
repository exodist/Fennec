package TEST::Fennec;
use strict;
use warnings;

use Fennec;

use Fennec::Util::Alias qw/
    Fennec::Runner
/;

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

tests exports {
    warning_like { done_testing }
     qr/calling done_testing\(\) is only required for Fennec::Standalone tests/,
     "done_testing in standalone only";

    throws_ok { use_or_skip XXX::Fake::Package }
        qr/SKIP: XXX::Fake::Package is not installed or insufficient version:/,
        "use_or_skip";

    throws_ok { use_or_skip XXX::Fake::Package, 'a', 'b', 'c' }
        qr/SKIP: XXX::Fake::Package is not installed or insufficient version:/,
        "use_or_skip";

    throws_ok { use_or_skip Data::Dumper, 1000000 }
        qr/SKIP: Data::Dumper is not installed or insufficient version: Data::Dumper version 1000000 required/,
        "use_or_skip w/ version";

    throws_ok { require_or_skip XXX::Fake::Package }
        qr/SKIP: XXX::Fake::Package is not installed/,
        "require_or_skip";

    $self->can_ok( qw/ M S / );

    isa_ok( M(), 'Fennec::TestFile::Meta' );
    is( M(), $self->fennec_meta, "Shortcut to meta" );

    is( ref( scalar( S() )), 'HASH', "Got stash ref" );
    S( a => 1 );
    is_deeply({ S() }, { a => 1 }, "List context" );
    S({ a => 2 });
    is_deeply({ S() }, { a => 2 }, "Replace" );
};

tests import => sub {
    my $ac = anonclass( use => 'Fennec' );
    can_ok( $ac, qw/ use_or_skip require_or_skip done_testing ok / );
    isa_ok( $ac, 'Fennec::TestFile' );
    ok( $ac->class->fennec_meta, "have meta" );

    throws_ok { $ac->use( 'Fennec' )}
        qr/Meta info for '@{[ $ac->class ]}' already initialized, did you 'use Fennec' twice\?/,
        "Using fennec twice causes error";

    throws_ok {
        local $Fennec::Runner::SINGLETON = undef;
        anonclass->use( 'Fennec' )
    } qr/Test runner not found/,
          "No runner error";

    throws_ok { package main; eval 'use Fennec; 1' || die( $@ ) }
        qr/You must put your tests into a package, not main/,
        "Using Fennec from main";
};

tests OO => sub {
    my $one = Fennec->new( caller => [ 'TEST::FENNEC', __FILE__, 1 ]);
    is( $one->test_class, 'TEST::FENNEC', "Test Class" );
    is( $one->test_file, __FILE__, "file" );
    is( $one->imported_line, 1, "line number" );
    is( $one->workflows, Runner->default_workflows, "Workflows" );
    is( $one->asserts, Runner->default_asserts, "asserts" );
    is( $one->root_workflow, Runner->root_workflow_class, "root_workflow" );

    ok( !TEST::FENNEC->isa( 'Fennec::TestFile' ), "Not a fennec subclass" );
    $one->subclass;
    isa_ok( 'TEST::FENNEC', 'Fennec::TestFile' );

    ok( !TEST::FENNEC->fennec_meta, "No Meta" );
    $one->init_meta;
    ok( TEST::FENNEC->fennec_meta, "have Meta" );

    ok( !TEST::FENNEC->can( $_ ), "can't $_" )
        for qw/done_testing use_or_skip require_or_skip/;
    $one->export_tools;
    can_ok( 'TEST::FENNEC', qw/done_testing use_or_skip require_or_skip/ );
};

tests exports => sub {

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
