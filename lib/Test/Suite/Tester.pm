package Test::Suite::Tester;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Test::Suite::Tester - Runs tests

=head1 DESCRIPTION

This is the class that kicks off L<Test::Suite>. Used by prove_suite.

=head1 EARLY VERSION WARNING

This is VERY early version. Test::Suite does not run yet.

Please go to L<http://github.com/exodist/Test-Suite> to see the latest and
greatest.

=cut

#}}}

sub run {
    my $class = shift;
    require Test::Suite;
    #Parse Args

    Test::Suite->new->run();
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
