package Test::Suite::Plugin::Warn;
use strict;
use warnings;

use Test::Suite::Plugin;
use Test::Suite::TestBuilderImposter;
use Test::Builder;
use Carp;

BEGIN {
    croak( 'Too late to capture Test::Warn' )
        if $INC{ 'Test/Warn.pm' };

    no warnings 'redefine';
    local *Test::Builder::new = sub {
        Test::Suite::TestBuilderImposter->new()
    };
    require Test::Warn;
}

use Test::Warn qw/warning_is warnings_are warning_like warnings_like warnings_exist/;



1;
