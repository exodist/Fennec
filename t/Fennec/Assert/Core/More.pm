package TEST::Fennec::Assert::Core::More;
use strict;
use warnings;

use Fennec workflows => [qw/Case Spec/];
use Fennec::Util::Accessors;

Accessors qw/ sd /;

our $CLASS = 'Fennec::Assert::Core::More';
eval "require $CLASS; 1" || die ( $@ );

cases 'String::Diff' => sub {
    my $self = shift;
    my $sd = eval 'require String::Diff; 1';

    case no_string_diff => sub {
        $self->sd( 0 );
        $Fennec::Assert::Core::More::DIFF = 0;
    };

    case string_diff => sub {
        $self->sd( 1 );
        $Fennec::Assert::Core::More::DIFF = 1;
    } if $sd;

    tests 'SCALAR_compare undef' => sub {
        local *scomp = \&Fennec::Assert::Core::More::SCALAR_compare;
        ok( !scomp( \undef, \undef ), "Nothing when comparing nothing" );
        ok( my $err = scomp( \undef, \'a' ), "error when have is nothing" );
        ok( $err eq "Expected: 'a' Got: undef", "Correct error" ) || diag( $err );
        ok( $err = scomp( \'a', \undef ), "error when expected is nothing" );
        ok( $err eq "Expected: undef Got: 'a'", "Correct error" ) || diag( $err );
        ok( $err = scomp( \'undef', \undef ), "error when undef and string 'undef'" );
        ok( $err eq "Expected: undef Got: 'undef'", "Correct error" ) || diag( $err );
        ok( $err = scomp( \undef, \'undef' ), "error when 'undef' and undef" );
        ok( $err eq "Expected: 'undef' Got: undef", "Correct error" ) || diag( $err );
    };

    tests 'SCALAR_compare same' => sub {
        local *scomp = \&Fennec::Assert::Core::More::SCALAR_compare;
        ok( !scomp( \1, \1 ), "Same number");
        ok( !scomp( \0, \0 ), "Same number");
        ok( !scomp( \"aaa", \"aaa" ), "Same string" );
        ok( !scomp( qr/a/, qr/a/ ), "Same regex" );
    };

    tests 'SCALAR_compare different' => sub {
        my $self = shift;
        local *scomp = \&Fennec::Assert::Core::More::SCALAR_compare;
        local *msg = sub {
            my ( $h, $w ) = @_;
            ( $w, $h ) = String::Diff::diff( $w, $h )
                if $self->sd;
            $h = "'$h'";
            $w = "'$w'";
            return "Expected: $w Got: $h";
        };
        ok( my $err = scomp( \1, \2 ), "Different number");
        ok( $err eq msg( 1, 2 ), "Correct msg" ) || diag( $err );
        ok( $err = scomp( \1, \0 ), "Different number");
        ok( $err eq msg( 1, 0 ), "Correct msg" );
        ok( $err = scomp( \0, \1 ), "Different number");
        ok( $err eq msg( 0, 1 ), "Correct msg" );
        ok( $err = scomp( \"aaa", \"bbb" ), "Different string" );
        ok( $err eq msg( 'aaa', 'bbb' ), "Correct msg" );
        ok( $err = scomp( qr/a/, qr/b/ ), "Different regex" );
        ok( $err eq msg( qr/a/, qr/b/ ), "Correct msg" );
    };

};

describe 'Primary tests' => sub {
    my $self = shift;
    before_each {
        $self->sd( 0 );
        $Fennec::Assert::Core::More::DIFF = 0;
    };

    it is_fail => sub {
        my $fail = capture {
            is( 'a', 'b', 'ab' );
            is( 0, 1, '01' );
            is( 1, 0, '10' );
            is( 1, 2, '12' );
            is( undef, 'a', 'ua' );
            is( 'a', undef, 'au' );
            is( qr/a/, qr/b/, 'regex' );
        };
        ok( @$fail == 7, 'num failed' );
        ok( !$fail->[$_]->pass, "$_ failed" ) for 0 .. @$fail - 1;
        ok(
            "ab-01-10-12-ua-au-regex"
            eq
            join('-', map { $_->name } @$fail ),
            "fail names"
        );
        is_deeply(
            [ map { @{ $_->stderr }} @$fail ],
            [
                qq/Expected: 'b' Got: 'a'/,
                qq/Expected: '1' Got: '0'/,
                qq/Expected: '0' Got: '1'/,
                qq/Expected: '2' Got: '1'/,
                qq/Expected: 'a' Got: undef/,
                qq/Expected: undef Got: 'a'/,
                "Expected: '" . qr/b/ . "' Got: '" . qr/a/ . "'",
            ],
            "Correct errors"
        );
    };

    it is_pass => sub {
        my $pass = capture {
            is( 'a', 'a', 'a' );
            is( 1, 1, 'one' );
            is( 0, 0, 'zero' );
            is( undef, undef, 'undef' );
            is( qr/a/, qr/a/, 'regex' );
        };
        ok( @$pass == 5, 'num passed' );
        ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. @$pass - 1;
        ok(
            "a-one-zero-undef-regex"
            eq
            join('-', map { $_->name } @$pass),
            "pass names"
        ) || diag( "a-1-0-undef-regex", join('-', map { $_->name } @$pass));
    };

    it isnt => sub {
        my $pass = capture {
            isnt( 'a', 'b', 'ab' );
            isnt( 0, 1, 'zero-one' );
            isnt( 1, 2, 'one-two' );
            isnt( undef, 1, "und-one" );
            isnt( qr/a/, qr/b/, 'regex' );
        };
        my $fail = capture {
            isnt( 'a', 'a', 'aa' );
            isnt( qr/a/, qr/a/, 'regex2' );
        };
        is( @$pass, 5, "5 passes" );
        is( @$fail, 2, "2 fails" );
        ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. @$pass - 1;
        ok( !$fail->[$_]->pass, "$_ failed" ) for 0 .. @$fail - 1;
        is_deeply(
            [ map { @{ $_->stderr }} @$fail ],
            [
                "Got: 'a' Wanted: Anything else",
                "Got: '" . qr/a/ . "' Wanted: Anything else",
            ],
            "Correct errors"
        );
    };

    tests like => sub {
        my $pass = capture {
            like( 'abcd', qr/^abcd$/, 'full' );
            like( 'efgh', qr/^efgh/, 'start' );
            like( 'ijkl', qr/ijkl$/, 'end' );
            like( 'abcd', 'abcd', 'string-not-regex' );
        };
        my $fail = capture {
            like( 'abcd', qr/efgh/, 'fail' );
            like( 'apple', qr/pear/, 'fail 2' );
        };
        ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. ( @$pass - 1 );
        ok( !$fail->[$_]->pass, "$_ failed" ) for 0 .. ( @$fail - 1 );
        is( $fail->[0]->stderr->[0], "'abcd' does not match (?-xism:efgh)", "Correct error" );
        is( $fail->[1]->stderr->[0], "'apple' does not match (?-xism:pear)", "Correct error" );
    };

    tests unlike => sub {
        my $fail = capture {
            unlike( 'abcd', qr/^abcd$/, 'full' );
            unlike( 'efgh', qr/^efgh/, 'start' );
            unlike( 'ijkl', qr/ijkl$/, 'end' );
        };
        my $pass = capture {
            unlike( 'abcd', qr/efgh/, 'a' );
            unlike( 'apple', qr/pear/, 'b' );
            unlike( 'apple', 'pear', 'c' );
        };
        ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. ( @$pass - 1 );
        ok( !$fail->[$_]->pass, "$_ failed" ) for 0 .. ( @$fail - 1 );
        is( $fail->[0]->stderr->[0], "'abcd' matches (?-xism:^abcd\$) (it shouldn't)", "Correct error" );
        is( $fail->[1]->stderr->[0], "'efgh' matches (?-xism:^efgh) (it shouldn't)", "Correct error" );
        is( $fail->[2]->stderr->[0], "'ijkl' matches (?-xism:ijkl\$) (it shouldn't)", "Correct error" );
    };

    tests can_ok => sub {
        my $self = shift;
        my $res = capture {
            $self->can_ok( 'ok' );
            $self->can_ok( 'fake name' );
            can_ok( [], 'apple' );
            can_ok( 'a', 'pear' );
            can_ok( $self, 'ok', 'can_ok' );
            can_ok( Fennec::Assert, 'import' );
            can_ok( undef, 'import' );
        };
        ok( $res->[0]->pass, "pass first" );
        ok( !$res->[1]->pass, "fail second" );
        is( $res->[1]->stderr->[0], "'$self' cannot 'fake name'", "Can't" );
        ok( !$res->[2]->pass, "fail third" );
        like( $res->[2]->stderr->[0], qr/'ARRAY.*' is not blessed/, "unblessed" );
        ok( !$res->[3]->pass, "fail fourth" );
        like( $res->[3]->stderr->[0], qr/'a' is not blessed/, "unblessed 2" );
        ok( $res->[4]->pass, "pass last" );
        like( $_->name, qr/->can(...)/, "name is correct" ) for @$res;
        ok( $res->[5]->pass, "pass post last - bareword" );
        ok( !$res->[6]->pass, "fail post post last - bareword" );
    };

    tests isa_ok => sub {
        my $self = shift;
        {
            package XXX::A;
            package XXX::B;
            package XXX::C;
            package XXX::Test::Package;
            use strict;
            use warnings;
            our @ISA = qw/ XXX::A XXX::B XXX::C /;
        }
        my $one = bless( [], 'XXX::Test::Package' );
        my $pass = capture {
            isa_ok( $one, 'XXX::Test::Package' );
            isa_ok( $one, 'XXX::A' );
            isa_ok( $one, 'XXX::B' );
            isa_ok( $one, 'XXX::C' );
            isa_ok( $one, 'XXX::A', 'XXX::B', 'XXX::C' );
            isa_ok( XXX::Test::Package, 'XXX::A', 'XXX::B', 'XXX::C' );
        };
        my $fail = capture {
            isa_ok( XXX::Test::Package, 'XXX::A', 'XXX::B', 'XXX::C', 'XXX::D' );
            isa_ok( $one, 'XXX::A', 'XXX::B', 'XXX::C', 'XXX::D' );
            isa_ok( $one, 'Fake' );
            isa_ok( 'a', 'Fake' );
            isa_ok( [], 'Fake' );
            isa_ok( undef, 'Fake' );
        };

        ok( $pass->[$_]->pass, "$_ passed" ) for 0 .. ( @$pass - 1 );
        ok( !$fail->[$_]->pass, "$_ failed" ) for 0 .. ( @$fail - 1 );

        is(
            $fail->[0]->stderr->[0],
            "'XXX::Test::Package' is not a 'XXX::D'",
            "error msg"
        );
        is(
            $fail->[1]->stderr->[0],
            "'$one' is not a 'XXX::D'",
            "error msg"
        );
        is(
            $fail->[2]->stderr->[0],
            "'$one' is not a 'Fake'",
            "error msg"
        );
        is(
            $fail->[3]->stderr->[0],
            "'a' is not blessed or class name",
            "error msg"
        );
        like(
            $fail->[4]->stderr->[0],
            qr/'ARRAY.*' is not blessed or class name/,
            "error msg"
        );
        is(
            $fail->[5]->stderr->[0],
            "undef is not blessed or class name",
            "error msg"
        );
    };

    tests is_deeply => sub {
        my $samesub = sub {1};
        my $pass = capture {
            is_deeply( [], [], "array" );
            is_deeply( {}, {}, 'hash' );
            is_deeply( "", "", "empty string" );
            is_deeply( undef, undef, 'undef' );
            is_deeply( 0, 0, 'zero' );
            is_deeply( 1, 1, 'number' );
            is_deeply( $samesub, $samesub, "subs direct" );
            is_deeply( qr/a/, qr/a/, "direct array" );
            is_deeply( [[]], [[]], "nested array" );
            is_deeply( [{}], [{}], "hash in array" );
            is_deeply(
                { a => ['a'], h => { t => 't' }},
                { a => ['a'], h => { t => 't' }},
                "Structure"
            );
            is_deeply(
                bless( { a => 'a' }, 'XXX' ),
                { a => 'a' },
                "object is hash"
            );
            is_deeply(
                { a => $samesub },
                { a => $samesub },
                "subs depth"
            );
            is_deeply(
                { a => qr/apple/ },
                { a => qr/apple/ },
                "Regex",
            );
            is_deeply(
                { obj => bless( { a => 'a' }, 'XXX' )},
                { obj => { a => 'a' }},
                "object at depth",
            );
            is_deeply(
                {
                    'a' .. 'f',
                    g => { 'x' => { 'y' => { z => [qw/a b c/]}}},
                },
                {
                    'a' .. 'f',
                    g => { 'x' => { 'y' => { z => [qw/a b c/]}}},
                },
                "Deep Same"
            );
        };
        my $fail = capture {
            is_deeply( 0, 1, "numeric mismatch zero" );
            is_deeply( 2, 1, "numeric mismatch 1-2" );
            is_deeply( undef, 0, "different false's" );
            is_deeply( [], {}, "hash and array" );
            is_deeply( [{}], [[]], "nesting" );
            is_deeply( ['a'], ['b'], "array element" );
            is_deeply( ['x', 'a', 'b'], ['x', 'c', 'd'], "multi-array-element" );
            is_deeply(
                { a => 'b', c => 'd', x => 'y' },
                { e => 'f', g => 'h', x => 'y' },
                "multi-element-hash"
            );
            is_deeply(
                bless( { a => 'b' }, 'XXX' ),
                bless( { c => 'd' }, 'YYY' ),
                "Objects that are different",
            );
            is_deeply(
                {
                    'a' .. 'f',
                    g => { 'x' => { 'y' => { z => [qw/a b c/]}}},
                },
                {
                    'a' .. 'f',
                    g => { 'x' => { 'y' => { z => [qw/e f g/]}}},
                },
                "Deep multi difference"
            );
            is_deeply( qr/a/, qr/b/, 'regex' );
            is_deeply( [qr/a/], [qr/b/], 'nested regex' );
        };

        ok( $_->pass, $_->name . " passed" ) for @$pass;
        ok( !$_->pass, $_->name . " failed" ) for @$fail;

        my @errors = map { @{ $_->stderr }} @$fail;

        is( $errors[0], "Expected: '1' Got: '0'", "error msg" );

        is( $errors[1], "Expected: '1' Got: '2'", "error msg" );

        is( $errors[2], "Expected: '0' Got: undef", "error msg" );

        is( $errors[3], "Expected: 'HASH' Got: 'ARRAY'", "error msg" );

        is( $errors[4], "[0] Expected: 'ARRAY' Got: 'HASH'", "error msg" );

        is( $errors[5], "[0] Expected: 'b' Got: 'a'", "error msg" );

        is( $errors[6], "[1] Expected: 'c' Got: 'a'", "error msg 1" );
        is( $errors[7], "[2] Expected: 'd' Got: 'b'", "error msg 2" );

        is( $errors[8], "{e} Expected: 'f' Got: undef", "error msg 1" );
        is( $errors[9], "{c} Expected: undef Got: 'd'", "error msg 2" );
        is( $errors[10], "{a} Expected: undef Got: 'b'", "error msg 3" );
        is( $errors[11], "{g} Expected: 'h' Got: undef", "error msg 4" );

        is( $errors[12], "{c} Expected: 'd' Got: undef", "error msg 1" );
        is( $errors[13], "{a} Expected: undef Got: 'b'", "error msg 2" );

        is( $errors[14], "{g}{x}{y}{z}[0] Expected: 'e' Got: 'a'", "error msg 1" );
        is( $errors[15], "{g}{x}{y}{z}[1] Expected: 'f' Got: 'b'", "error msg 2" );
        is( $errors[16], "{g}{x}{y}{z}[2] Expected: 'g' Got: 'c'", "error msg 3" );

        is( $errors[17], "Expected: '(?-xism:b)' Got: '(?-xism:a)'", "error msg" );
        is( $errors[18], "[0] Expected: '(?-xism:b)' Got: '(?-xism:a)'", "error msg" );
    };

    tests advanced_is => sub {
        my $fail = capture {
            advanced_is( name => 'no want or got' );
            advanced_is( want => 'a', name => 'no got' );
            advanced_is( got => 'a', name => 'no want' );
            advanced_is( got => 'a', want => 'b', name => 'mismatch' );
            advanced_is(
                got => bless( [1], 'XXX' ),
                want => bless( [1], 'YYY' ),
                name => "blessed differently",
                bless => 1,
            );
            advanced_is(
                got => bless( [1], 'XXX' ),
                want => [],
                name => "want not blessed",
                bless => 1,
            );
            advanced_is(
                want => bless( [1], 'XXX' ),
                got => [],
                name => "got not blessed",
                bless => 1,
            );
            advanced_is(
                want => sub {1},
                got => sub {1},
                name => "diff sub ref",
                no_code_checks => 0,
            );
            advanced_is(
                want => sub {1},
                got => {},
                name => "sub and hash",
                no_code_checks => 0,
            );
        };
        my $pass = capture {
            advanced_is( got => 'a', want => 'a', name => 'scalar' );
            advanced_is(
                got => bless( [1], 'XXX' ),
                want => bless( [1], 'XXX' ),
                name => "blessed same",
                bless => 1,
            );
            advanced_is(
                got => 'a',
                want => 'a',
                name => "not blessed",
                bless => 1,
            );
            advanced_is(
                want => sub {1},
                got => sub {1},
                name => "diff sub ref",
                no_code_checks => 1,
            );
            my $sub = sub {1};
            advanced_is(
                want => $sub,
                got => $sub,
                name => "same sub ref",
                no_code_checks => 0,
            );
        };

        ok( $_->pass, $_->name . " passed" ) for @$pass;
        ok( !$_->pass, $_->name . " failed" ) for @$fail;

        is(
            $fail->[0]->stderr->[0],
            "You must specify 'got' and 'want'",
            "correct error"
        );
        is(
            $fail->[1]->stderr->[0],
            "You must specify 'got' and 'want'",
            "correct error"
        );
        is(
            $fail->[2]->stderr->[0],
            "You must specify 'got' and 'want'",
            "correct error"
        );
        is(
            $fail->[3]->stderr->[0],
            "Expected: 'b' Got: 'a'",
            "correct error"
        );
        is(
            $fail->[4]->stderr->[0],
            "Expected: 'bless( \$obj, \"YYY\" )' Got: 'bless( \$obj, \"XXX\" )'",
            "correct error"
        );
        is(
            $fail->[5]->stderr->[0],
            "Expected: 'not blessed' Got: 'bless( \$obj, \"XXX\" )'",
            "correct error"
        );
        is(
            $fail->[5]->stderr->[1],
            "[0] Expected: undef Got: '1'",
            "correct error"
        );
        is(
            $fail->[6]->stderr->[0],
            "Expected: 'bless( \$obj, \"XXX\" )' Got: 'not blessed'",
            "correct error"
        );
        is(
            $fail->[6]->stderr->[1],
            "[0] Expected: '1' Got: undef",
            "correct error"
        );
        like(
            $fail->[7]->stderr->[0],
            qr/Expected: 'CODE\(.*\)' Got: 'CODE\(.*\)'/,
            "correct error"
        );
        is(
            $fail->[8]->stderr->[0],
            "Expected: 'CODE' Got: 'HASH'",
            "correct error"
        );
    };

    tests compare_args => sub {
        no strict 'refs';
        my @err = &{ $CLASS . '::compare'}( 1 );
        is( $err[0], "Not enough arguments", "Not enough arguments" );
    };
};

1;
