#!/usr/bin/perl
use strict;
use warnings;
package TEST::BeginStuff;

use Fennec::Standalone;

use_or_skip Something::That::Is::Fake;

die( "Should never get here" );

done_testing;
