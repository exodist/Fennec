package TEST::Fennec::Assert;
use strict;
use warnings;

use Fennec asserts => [ 'Core', 'Interceptor' ];
use Time::HiRes qw/time sleep/;
our $CLASS = 'Fennec::Assert';

our $HAVE_TB = eval 'require Test::Builder; 1';

tests use_package => sub {
    require_ok $CLASS;
    my $ac = anonclass( use => $CLASS );
    $ac->can_ok( qw/tb_wrapper tester util result diag test_caller note/ );
    $ac->isa_ok( 'Exporter::Declare::Base' );
};

tests tb_overrides => (
    skip => $HAVE_TB ? undef : 'No Test::Builder',
    method => sub {
        for my $method ( keys %Fennec::Assert::TB_OVERRIDES ) {
            no strict 'refs';
            is(
                $Fennec::Assert::TB_OVERRIDES{ $method },
                \&{'Test::Builder::' . $method},
                "Overrode Test\::Builder\::$method\()"
            );
            can_ok( 'Test::Builder', "real_$method" );
        }
        lives_ok { Test::Builder::_my_exit } "TB::_my_exit";
        lives_ok { Test::Builder::exit() } "TB::exit";
        my $res = capture {
            Test::Builder->ok( 1, "pass" );
            Test::Builder->ok( 0, "fail" );
            Test::Builder->diag( "Diag" );
            Test::Builder->note( "Note" );
        };
        is( @$res, 4, "4 output items" );
    },
);

tests declare_exports => sub {
    my $ac = anonclass( use => [$CLASS] );
    my $acinst = $ac->new();
    my $result = 0;
    $acinst->util( do_stuff => sub { $result++ });
    $acinst->tester( is_stuff => sub { $acinst->result( pass => $_[0], name => $_[1] ) });
    no strict 'refs';
    advanced_is(
        name => "Export added",
        got => ref($acinst)->exports,
        want => { do_stuff => sub {}, is_stuff => sub {} },
        no_code_checks => 1,
    );
    use_into_ok( ref($acinst), main::__dce );
    can_ok( main::__dce, 'do_stuff', 'is_stuff' );
    main::__dce::do_stuff();
    is( $result, 1, "Function behaved properly" );
    main::__dce::do_stuff();
    is( $result, 2, "Function behaved properly (double check)" );
    my $cap = capture {
        main::__dce::is_stuff( 1, "a" );
        main::__dce::is_stuff( 0, "b" );
    };
    is( @$cap, 2, "captured 2 results" );
    is( $cap->[0]->line, ln(-4), "First result, added line number" );
    is( $cap->[1]->line, ln(-4), "Second result, added line number" );
    is( $cap->[0]->file, __FILE__, "Set file name" );
    ok( $cap->[0]->benchmark, "Added benchmark" );
    is_deeply(
        $cap->[1]->stderr,
        ['$_[0] = \'0\''],
        "Added diag when missing"
    );
    ok( $cap->[0]->pass, "First result passed" );
    ok( !$cap->[1]->pass, "Second result failed" );
    is( $cap->[0]->name, 'a', "First name" );
    is( $cap->[1]->name, 'b', "Second name" );
};

tests export_exceptions => sub {
    my $ac = anonclass( use => $CLASS );
    my $acinst = $ac->new;
    my $instclass = $ac->class;
    throws_ok { $acinst->tester( 'fake' )}
        qr/No code found in '$instclass' for exported sub 'fake'/,
        "Must provide sub for tester";

    my $res = capture {
        $acinst->tester( dies => sub { die( 'I died' )});
        anonclass( use => $ac->class )->new->dies(1);
    };
    is( @$res, 1, "1 result" );
    ok( !$res->[0]->pass, "result failed" );
    like( $res->[0]->stderr->[0], qr/I died/, "diag for fail" );
};

tests tb_wrapper => (
    skip => $HAVE_TB ? undef : 'No Test::Builder',
    method => sub {
        my $wrapped = Fennec::Assert::tb_wrapper( sub($$) {
            Test::Builder->new->ok( @_ );
            Test::Builder->new->diag( 'a message' );
        });
        is( prototype( $wrapped ), '$$', "Preserve prototype" );
        my $res = capture { $wrapped->( 1, 'name' ) };
        is( @$res, 1, "1 output" );
        ok( $res->[0]->pass, "passed" );
        is( $res->[0]->stderr->[0], "a message", "message" );
        $wrapped = Fennec::Assert::tb_wrapper( sub {
            Test::Builder->new->diag( 'a message' );
        });
        ok( !prototype( $wrapped ), "No prototype" );
        $res = capture { $wrapped->( 1, 'name' ) };
        ok( !$res->[0]->isa('Fennec::Output::Result'), "Not a result" );
        is( $res->[0]->stderr->[0], "a message", "message" );
    },
);

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
