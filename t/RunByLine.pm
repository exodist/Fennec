package TEST::RunByLine;
use strict;
use warnings;
use Fennec;

use Fennec::Util::Alias qw/
    Fennec::Workflow
    Fennec::TestSet
    Fennec::TestSet::SubSet
/;

use Fennec::Util::Accessors;
Accessors qw/item/;

cases 'Multi-Line' => sub {
    my $self = shift;
    my ( $start, $end ) = map { ln($_) } 3, 7;
    for my $type ( Workflow(), TestSet() ) {
        case $type => sub {
            my $item = $type->new( 'Example', sub {
                my $x = 1;

                return $x;
            });
            $item->observed(1) if $item->can( 'observed' );
            $self->item( $item );
        }
    }

    tests 'proper start and end' => sub {
        my $self = shift;
        is( $self->item->start_line, $start, "Proper start" );
        is( $self->item->end_line, $end, "Proper end" );
        is_deeply(
            [$self->item->lines_for_filter],
            [ $start, $end ],
            "filter lines"
        );
        $self->item( undef );
    };
};

cases 'Single-Line' => sub {
    my $self = shift;
    my $line = ln(3);
    for my $type ( Workflow(), TestSet() ) {
        case $type => sub {
            my $item = $type->new( 'Example', sub { 1 });
            $item->observed(1) if $item->can( 'observed' );
            $self->item( $item );
        }
    }

    tests 'proper start and end' => sub {
        my $self = shift;
        is( $self->item->start_line, $line, "Proper start" );
        is( $self->item->end_line, $line, "Proper end" );
        is_deeply(
            [$self->item->lines_for_filter],
            [ $line, $line ],
            "filter lines"
        );
        $self->item( undef );
    };
};

my $ln = ln(1);
sub blah {
    1;
}

tests not_anon => sub {
    my $item = Workflow->new( 'blah', \&blah );
    is( $item->start_line, $ln, "Proper start" );
    is( $item->end_line, undef, "No end" );
};

1;
