package Test::Workflow::Meta;
use strict;
use warnings;

use Test::Workflow::Layer;

use Fennec::Util qw/accessors array_accessors/;

accessors qw/test_class build_complete root_layer/;

sub new {
    my $class = shift;
    my ( $test_class ) = @_;
    return bless({
        test_class => $test_class,
        root_layer => Test::Workflow::Layer->new(),
    }, $class );
}

1;
