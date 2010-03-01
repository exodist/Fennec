package Test::Suite::Tester;
use strict;
use warnings;

sub run {
    my $class = shift;
    require Test::Suite;
    #Parse Args

    Test::Suite->new->run();
}

1;
