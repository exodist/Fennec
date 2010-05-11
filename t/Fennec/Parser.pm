package TEST::Fennec::Declare;
use strict;
use warnings;
use Fennec;

tests simple {
    ok( $self, "Magically got self" );
    $self->isa_ok( 'TEST::Fennec::Declare' );
    $self->isa_ok( 'Fennec::TestFile' );
    ok( 1, "In declared tests!" );
}

tests 'complicated name' {
    ok( $self, "Magically got self" );
    $self->isa_ok( 'TEST::Fennec::Declare' );
    $self->isa_ok( 'Fennec::TestFile' );
    ok( 1, "Complicated name!" );
}

tests old => sub {
    ok( 1, "old style still works" );
};

tests old_deep => (
    method => sub { ok( 1, "old with depth" )},
);

tests add_specs ( todo => 'not really todo' ) {
    ok( $self, "Magically got self" );
    $self->isa_ok( 'TEST::Fennec::Declare' );
    $self->isa_ok( 'Fennec::TestFile' );
    TODO {
        ok( 0, "This should be todo" );
    } "Todo from Fennec bug #58";
}

tests open_next_line
{
    ok( $self, "Magically got self" );
    ok( 1, "open on next line" );
}

cases some_cases {
    ok( $self, "Magically got self" );
    $self->isa_ok( 'TEST::Fennec::Declare' );
    $self->isa_ok( 'Fennec::TestFile' );

    my $x = 0;
    case case_a { $x = 10 }
    case case_b { $x = 100 }
    case case_c {
        ok( $self, "Magically got self" );
        $self->isa_ok( 'TEST::Fennec::Declare' );
        $self->isa_ok( 'Fennec::TestFile' );
        $x = 1000
    }

    tests divisible_by_ten { ok( !($x % 10), "$x/10" )}
    tests positive { ok( $x, "$x is positive" )}
}

describe a_describe {
    ok( $self, "Magically got self" );
    $self->isa_ok( 'TEST::Fennec::Declare' );
    $self->isa_ok( 'Fennec::TestFile' );

    my $x = 0;
    before_each {
        ok( $self, "Magically got self" );
        $self->isa_ok( 'TEST::Fennec::Declare' );
        $self->isa_ok( 'Fennec::TestFile' );
    }
    before_each { ok( $self, "Magically got self" )}
    after_each { ok( $self, "Magically got self" )}
    after_each {
        ok( $self, "Magically got self" )
    };

    before_each { $x = 10 };

    after_each { $x = 0 };

    it is_ten { is( $x, 10, "x is 10" ); $x = 100 }
    it is_not_100 { isnt( $x, 100, "x is not 100" ); $x = 100 }
}

tests errors {
    eval 'tests { 1 }';
    my $msg = $@;
    like(
        $msg,
        qr/You must provide a name to tests\(\) at /
    );
}

1;
