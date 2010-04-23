#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Util::Alias qw/
    Fennec::Runner
/;

'Fennec::Runner'->init(
    collector => 'Files',
    cull_delay => .01,
    default_asserts => [qw/Core Interceptor/],
    default_workflows => [qw/Spec Case Methods/],
    filetypes => [qw/ Module /],
    handlers => [qw/ TAP /],
    ignore => undef,
    parallel_files => 2,
    parallel_tests => 2,
    random => 1,
);

Runner()->run_tests;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
