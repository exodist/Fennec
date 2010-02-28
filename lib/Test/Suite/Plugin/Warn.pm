package Test::Suite::Plugin::Warn;
use strict;
use warnings;

use Test::Suite::Plugin;
use Test::Suite::TestBuilderImposter;
use Test::Builder;
use Carp;

our @SUBS;
BEGIN {
    @SUBS = qw/warning_is warnings_are warning_like warnings_like warnings_exist/;
}

use Test::Warn @SUBS;

tester $_ => $_ for @SUBS;

1;
