package TEST::Fennec::TestSet;
use strict;
use warnings;

use Fennec;
my $CLASS = 'Fennec::TestSet';
use_ok( $CLASS );

tests 'warn for unobserved' => sub {
    my $line;
    my ( $warn ) = capture_warnings {
        do {
            my $set = $CLASS->new( 'xxx', file => 'file', line => '1', method => sub { 1 });
            $set = undef
        };
    };
    my @parts = split('\n', $warn );
    my $total = @parts;

    is(
        shift( @parts ),
        "Testset was never observed by the runner:",
        "Warning Part " . ($total - @parts )
    );
    is( shift( @parts ), "\tName: xxx", "Warning Part " . ($total - @parts ));
    is( shift( @parts ), "\tFile: file", "Warning Part " . ($total - @parts ));
    is( shift( @parts ), "\tLine: 1", "Warning Part " . ($total - @parts ));
    is( shift( @parts ), "", "Warning Part " . ($total - @parts ));
    is(
        shift( @parts ),
        "This is usually due to nesting a workflow within another workflow that does not",
        "Warning Part " . ($total - @parts )
    );
    is( shift( @parts ), "support nesting.", "Warning Part " . ($total - @parts ));
    is( shift( @parts ), "", "Warning Part " . ($total - @parts ));
    is( shift( @parts ), "Workflow stack:", "Warning Part " . ($total - @parts ));
    is( shift( @parts ), "No Workflow", "Warning Part " . ($total - @parts ));
};

tests test_todo {
    my $set = Fennec::TestSet->new(
        'todo stuff',
        method => sub { ok( 0, "false result" ) },
        todo => 'this is todo',
        line => 999,
        file => 'none',
        observed => 1,
        workflow => __PACKAGE__->fennec_meta->root_workflow,
    );

    my $results = capture {
        $set->run();
    }
    is( $results->[0]->pass, 0, "test did not pass" );
    is( $results->[0]->todo, 'this is todo', "Test marked todo" );
}

tests finishing {
    my $set = Fennec::TestSet->new(
        'finishing',
        method => sub { },
        line => 999,
        file => 'none',
        observed => 1,
        workflow => __PACKAGE__->fennec_meta->root_workflow,
    );

    my $results = capture {
        $set->run();
    }
    is( $results->[0]->finishes, 'testset', "finished testset" );
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
