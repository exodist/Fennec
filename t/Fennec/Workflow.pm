package TEST::Fennec::Workflow;
use strict;
use warnings;
use Fennec;

require_ok( 'Fennec::Workflow' );

tests 'add_item after build' => sub {
    my $workflow = Fennec::Workflow->new( 'fake', sub {1} );
    my $nested = Fennec::Workflow->new( 'fake nested', sub {1} );
    my $late = Fennec::Workflow->new( 'fake nested', sub {1} );

    ok( !$workflow->built, "Not Built" );
    lives_ok { $workflow->add_item( $nested )};

    $workflow->built(1);
    ok( $workflow->built, "Built" );
    my $ln = ln(1);
    my ( $ok, $msg ) = live_or_die { $workflow->add_item( $late )};
    ok( !$ok, "add_item died" );
    is( $msg, <<EOT, "Useful message" );
Attempt to add 'Fennec\::Workflow(fake nested)' to workflow 'fake' after the workflow has already been built.
Did you try to define a workflow or testset inside a testset?
File: @{[ __FILE__ ]}
Line: 19
EOT
};

1;
