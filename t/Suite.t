#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;
use Test::Builder::Tester;

my $CLASS = 'Test::Suite';
require Test::Suite;

#{{{ Test _handle_result before we override it.
test_out( "ok 1" );
$CLASS->_handle_result({ result => 1 });
test_out( "ok 2 - NAME" );
$CLASS->_handle_result({ result => 1, name => 'NAME' });

test_out( "not ok 3 - NAME" );
test_fail(+4);
#test_diag( "\tTest failed in file filename\t\non line 1" );
test_diag( "a" );
test_diag( "b" );
$CLASS->_handle_result({
    result => 0,
    name => 'NAME',
    filename => 'filename',
    line => '1',
    debug => [ 'a', 'b' ],
});

test_diag( "xxx" );
$CLASS->_handle_result({ diag => "xxx" });

test_test( "_handle_result works" );
#}}}

my @results;
{
    no warnings 'redefine';
    *Test::Suite::_handle_result = sub { shift and push @results => @_ };
}

Test::Suite->_handle_result( 'a' );
is_deeply( \@results, [ 'a' ], "Saving results" );
@results = ();

my $one = $CLASS->new();
is( $one, $CLASS->new(), "singleton" );
is( $one, $CLASS->get(), "singleton - get" );
is( $one->parent_pid, $$, "Parent PID" );
is( $one->pid, $$, "PID" );
isa_ok( $one->{ socket }, 'IO::Socket::UNIX' );
like( $one->socket_file, qr{./\.test-suite\.$$\.....$}, "Socket file" );

my $test = bless( {}, 'Some::Package' );
$one->add_test( $test );
is( $one->get_test( 'Some::Package' ), $test, "Got test" );

throws_ok { $one->add_test( $test )}
          qr/Some::Package has already been added as a test/,
          "No overide";

ok( $one->is_parent, "is parent" );

{
    package My::Test;
    use strict;
    use warnings;

    use Test::Suite;


}

done_testing;

__END__

sub import {
    my $class = shift;
    my %options = @_;
    my ( $package ) = caller();

    {
        no strict 'refs';
        push @{ $package . '::ISA' } => 'Test::Suite::TestBase';
    }

    my $self = $class->get;
    my $test = $package->new(\%options);
    $self->add_test( $test );

    # If there are no options then don't continue.
    return $test unless keys %options;

    my $no_plugin = { map { substr($_, 1) => 1 } grep { m/^-/ } @{ $options{ plugins }}};
    my %seen;
    for my $plugin ( @{ $options{ plugins }}, qw/Warn Exception More Simple/) {
        next if $seen{ $plugin }++;
        next if $no_plugin->{ $plugin };

        my $name = "Test\::Suite\::Plugin\::$plugin";
        eval "require $name" || die( $@ );
        $name->export_to( $package );
    }

    Test::Suite::Grouping->export_to( $package );

    if ( my $tested = $options{ tested }) {
        my @args = $options{ import_args };
        local *{"$package\::_import_args"} = sub { @args };
        my $r = eval "package $package; use $tested _import_args(); 'xxgoodxx'";
        die( $@ ) unless $r eq 'xxgoodxx';
    }
    return $test;
}
