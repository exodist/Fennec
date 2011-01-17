#!/usr/bin/perl
package XXX;
use strict;
use warnings;

use Test::More;
use Test::Workflow;

tests outer => sub {
    tests inner => sub {

    };
};

done_testing();
