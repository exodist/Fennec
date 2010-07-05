package Test::Suite;
use strict;
use warnings;

BEGIN {
    require Fennec;
    *Test::Suite:: = *Fennec::;
}

1;

=pod

=head1 NAME

Test::Suite - Framework upon which intercompatible testing solutions can be
built.

=head1 DESCRIPTION

This is the original package for what is now called L<Fennec>. Test::Suite is
now an alias to L<Fennec>. You may continue to use Test::Suite instead of
L<Fennec> in your test modules.

    package MyTest;
    use Test::Suite;

Identical to:

    package MyTest;
    use Fennec;

=head1 ABOUT

Please read the L<Fennec> docs.

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back


=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
