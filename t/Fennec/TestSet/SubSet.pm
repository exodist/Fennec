package TEST::Fennec::TestSet::SubSet;
use strict;
use warnings;
use Fennec;

use Carp;

use Fennec::Util::Alias qw/
    Fennec::Workflow
/;

tests load => sub {
    require_ok( 'Fennec::TestSet::SubSet' );
};

tests setup_causing_skip => sub {
    my $self = shift;
    my $one = Fennec::TestSet::SubSet->new(
        workflow => Fennec::Workflow->new( 'test' => sub {1})
    );
    $one->workflow->parent( $self );
    $one->add_setup( 'setup' => sub { confess 'SKIP: Setup says skip' });
    $one->add_testset( 'test' => sub { ok( 0, "Should not get here" )});
    $one->observed(1);
    lives_and {
        my $res = capture { $one->run };
        is( @$res, 1, "One result" );
        is( $res->[0]->skip, "Setup says skip", "Result is todo" )
    } "running a setup with a SKIP exception.";
};

1;
