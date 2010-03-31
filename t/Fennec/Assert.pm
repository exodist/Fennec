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
    $ac->can_ok( qw/tb_wrapper tester util result diag/ );
    $ac->isa_ok( 'Fennec::Assert' );
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
    },
);

tests declare_exports => sub {
    my $ac = anonclass( use => $CLASS )->new();
    my $result = 0;
    $ac->util( do_stuff => sub { $result++ });
    $ac->tester( is_stuff => sub { $ac->result( pass => $_[0], name => $_[1] ) });
    no strict 'refs';
    advanced_is(
        name => "Export added",
        got => ref($ac)->exports,
        want => { do_stuff => sub {}, is_stuff => sub {} },
        no_code_checks => 1,
    );
    use_into_ok( ref($ac), main::__dce );
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
        $cap->[1]->stdout,
        ['$_[0] = \'0\''],
        "Added diag when missing"
    );
    ok( $cap->[0]->pass, "First result passed" );
    ok( !$cap->[1]->pass, "Second result failed" );
    is( $cap->[0]->name, 'a', "First name" );
    is( $cap->[1]->name, 'b', "Second name" );
};

tests export_exceptions => sub {
    my $ac = anonclass( use => $CLASS )->new();
    throws_ok { $ac->util() }
        qr/You must provide a name to util\(\)/,
        "must provide a name to util";
    throws_ok { $ac->util( 'fake' )}
        qr/No sub found for function fake/,
        "Must provide sub";
    throws_ok { $ac->tester() }
        qr/You must provide a name to tester\(\)/,
        "must provide a name to tester";
    throws_ok { $ac->tester( 'fake' )}
        qr/No sub found for function fake/,
        "Must provide sub";
};

tests tester_wrapper_exceptions => sub {

};

1;

__END__

    my $wrapsub = sub {
        my @args = @_;
        my $outresult;
        my $benchmark;
        my ( $caller, $file, $line ) = caller;
        my %caller = _first_test_caller_details();
        try {
            no warnings 'redefine';
            no strict 'refs';
            local *{ $assert_class . '::result' } = sub {
                shift( @_ ) if blessed( $_[0] )
                            && blessed( $_[0] )->isa( __PACKAGE__ );
                croak( "tester functions can only generate a single result." )
                    if $outresult;
                $outresult = { @_ }
            };
            $benchmark = timeit( 1, sub { $sub->( @args )});

            # Try to provide a minimum diag for failed tests that do not provide
            # their own.
            if ( !$outresult->{ pass }
            && ( !$outresult->{ stdout } || !@{ $outresult->{ stdout }})) {
                my @diag;
                $outresult->{ stdout } = \@diag;
                for my $i ( 0 .. (@args - 1)) {
                    my $arg = $args[$i];
                    $arg = 'undef' unless defined( $arg );
                    next if "$arg" eq $outresult->{ name } || "";
                    push @diag => "\$_[$i] = '$arg'";
                }
            }

            result(
                %caller,
                benchmark => $benchmark || undef,
                %$outresult
            ) if $outresult;
        }
        catch {
            result(
                pass => 0,
                %caller,
                stdout => [ "$name died: $_" ],
            );
        };
    };

sub diag {
    shift( @_ ) if blessed( $_[0] )
                && blessed( $_[0] )->isa( __PACKAGE__ );
    Fennec::Output::Diag->new( stdout => \@_ )->write;
}

sub result {
    shift( @_ ) if blessed( $_[0] )
                && blessed( $_[0] )->isa( __PACKAGE__ );
    return unless @_;
    my %proto = @_;
    Result->new(
        @proto{qw/file line/} ? () : _first_test_caller_details(),
        %proto,
    )->write;
}

sub tb_wrapper(&) {
    shift( @_ ) if blessed( $_[0] )
                && blessed( $_[0] )->isa( __PACKAGE__ );
    my ( $orig ) = @_;
    my $proto = prototype( $orig );
    my $wrapper = sub {
        my @args = @_;
        local $TB_OK = 1;
        local ( $TB_RESULT, @TB_DIAGS );
        my $benchmark = timeit( 1, sub { $orig->( @args )});
        return diag( @TB_DIAGS ) unless $TB_RESULT;
        return result(
            pass      => $TB_RESULT->[0],
            name      => $TB_RESULT->[1],
            benchmark => $benchmark,
            stdout    => [@TB_DIAGS],
        );
    };
    return $wrapper unless $proto;
    # Preserve the prototype
    return eval "sub($proto) { \$wrapper->(\@_) }";
}

sub _first_test_caller_details {
    my $current = 1;
    my ( $caller, $file, $line );
    do {
        ( $caller, $file, $line ) = caller( $current );
        $current++;
    } while $caller && !$caller->isa( 'Fennec::TestFile' );

    return (
        file => $file || "N/A",
        line => $line || "N/A",
    );
}
