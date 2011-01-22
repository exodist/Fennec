package Fennec::Meta;
use strict;
use warnings;

use Fennec::Util qw/accessors/;

accessors qw/utils parallel class fennec base test_sort/;

sub new {
    my $class = shift;
    my %proto = @_;
    bless({
        $proto{fennec}->defaults(),
        %proto,
    }, $class);
}

1;
