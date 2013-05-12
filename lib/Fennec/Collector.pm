package Fennec::Collector;
use strict;
use warnings;

use Carp qw/confess/;
use Fennec::Util qw/accessors/;

accessors qw/test_count/;

my @PREFERENCE = qw{
    Fennec::Collector::SQLite
    Fennec::Collector::TempFiles
};

sub new {
    my $class = shift;
    my @preference = @_ ? @_ : @PREFERENCE;

    for my $module (@preference) {
        my $file = $module;
        $file =~ s{::}{/}g;
        $file .= '.pm';
        require $file;

        next unless $module->validate_env;
        my $collector = $module->new;
        $collector->initialize;
        return $collector;
    }

    die "Could not find a valid collector!";
}

sub collect      { confess "Must override collect" }
sub report       { confess "Must override report" }
sub validate_env { confess "must override validate_env" }

sub finish {
    my $self = shift;
    my $count = $self->test_count || 0;
    print STDOUT "1..$count\n";
}

sub inc_test_count {
    my $self = shift;
    my $count = $self->test_count || 0;
    $self->test_count( $count + 1 );
}

sub initialize {
    my $self = shift;
    require Test::Builder;

    my $tbout = tie( *TBOUT, 'Fennec::Collector::_Handle', 'STDOUT', $self );
    my $tberr = tie( *TBERR, 'Fennec::Collector::_Handle', 'STDERR', $self );

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

sub update_wfmeta { }

package Fennec::Collector::_Handle;

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
