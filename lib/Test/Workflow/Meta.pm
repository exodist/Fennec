package Test::Workflow::Meta;
use strict;
use warnings;

use Test::Workflow::Layer;

use Fennec::Util qw/accessors/;

accessors qw/test_class build_complete root_layer test_run test_sort ok diag/;

sub new {
    my $class = shift;
    my ( $test_class ) = @_;
    return bless({
        test_class => $test_class,
        root_layer => Test::Workflow::Layer->new(),
    }, $class );
}

1;
