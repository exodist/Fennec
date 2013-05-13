package Fennec::Collector::TB;
use strict;
use warnings;
use Carp qw/confess/;

use base 'Fennec::Collector';

sub ok   { shift; Test::Builder->new->ok(@_) }
sub diag { shift; Test::Builder->new->diag(@_) }
sub report { confess "Must override report" }

sub finish {
    my $self = shift;
    my $count = $self->test_count || 0;
    print STDOUT "1..$count\n";
}

sub initialize {
    my $self = shift;
    require Test::Builder;

    my $tbout = tie( *TBOUT, 'Fennec::Collector::TB::_Handle', 'STDOUT', $self );
    my $tberr = tie( *TBERR, 'Fennec::Collector::TB::_Handle', 'STDERR', $self );

    my $tb = Test::Builder->new();
    $tb->use_numbers(0);
    $tb->no_header(1);
    $tb->no_ending(1);

    my $old = select(TBOUT);
    $| = 1;
    select(TBERR);
    $| = 1;
    select($old);

    $tb->output( \*TBOUT );
    $tb->todo_output( \*TBOUT );
    $tb->failure_output( \*TBERR );
}

package Fennec::Collector::TB::_Handle;

use Fennec::Util qw/accessors get_test_call/;

accessors qw/name collector/;

sub TIEHANDLE {
    my $class = shift;
    my ( $name, $collector ) = @_;
    return bless( {name => $name, collector => $collector}, $class );
}

sub PRINT {
    my $self = shift;
    my @data = @_;
    my @call = get_test_call();

    $self->collector->report(
        pid    => $$,
        source => join( ", " => @call[0 .. 2] ),
        data   => \@data,
        name   => $self->name,
    );
}

1;
