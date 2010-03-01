package Fennec::Tester;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Fennec::Tester - Runs tests

=head1 DESCRIPTION

This is the class that kicks off L<Fennec>. Used by prove_fennec.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=cut

#}}}

sub run {
    my $class = shift;
    require Fennec;
    #Parse Args

    Fennec->new->run();
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
