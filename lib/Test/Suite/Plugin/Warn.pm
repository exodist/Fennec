package Test::Suite::Plugin::Warn;
use strict;
use warnings;

use Test::Suite::Plugin;
use Test::Suite::TestBuilderImposter;
use Test::Builder;
use Carp;

our @SUBS;
BEGIN {
    croak( 'Too late to capture Test::Warn' )
        if $INC{ 'Test/Warn.pm' };

    no warnings 'redefine';
    local *Test::Builder::new = sub {
        Test::Suite::TestBuilderImposter->new()
    };

    # Test::Warn creates a single Test::Builder at load.
    require Test::Warn;

    @SUBS = qw/warning_is warnings_are warning_like warnings_like warnings_exist/;
}

use Test::Warn @SUBS;

tester $_ => wrap_sub( $_ ) for @SUBS;

1;
