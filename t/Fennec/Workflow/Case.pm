package TEST::Fennec::Workflow::Case;
use strict;
use warnings;

use Fennec workflows => [ 'Case' ],
           sort => 1,
           no_fork => 1;

use Fennec::Util::Accessors;

Accessors qw/ state /;

sub init {
    my $self = shift;
    $self->state({});
}

cases 'a - first' => sub {
    my $self = shift;
    case 'case a' => sub {
        $self->state->{cases}->{a}++
    };
    case 'case b' => sub {
        $self->state->{cases}->{b}++
    };
    case 'case c' => sub {
        $self->state->{cases}->{c}++
    };

    tests 'tests a' => sub {
        $self->state->{sets}->{a}++
    };
    tests 'tests b' => sub {
        $self->state->{sets}->{b}++
    };
    tests 'tests c' => sub {
        $self->state->{sets}->{c}++
    };
};

tests 'z - Run this last' => sub {
    my $self = shift;
    is_deeply(
        $self->state,
        {
            cases => {
                a => 3,
                b => 3,
                c => 3,
            },
            sets => {
                a => 3,
                b => 3,
                c => 3,
            },
        },
        "3 sets x 3 cases, all run 3 times"
    );
};

1;
