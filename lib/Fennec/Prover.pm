package Fennec::Prover;
use strict;
use warnings;
use Fennec::Runner;

my $SINGLETON;

sub new {
    my $class = shift;
    return $SINGLETON if $SINGLETON;

    my %options = @_;
    my $self = bless( {}, $class );
    $SINGLETON = $self;
    %options = ( %options, $self->cli_options );
    my $runner = Fennec::Runner->new( %options );
    return $runner;
}

sub get { goto &new }

sub cli_options {
    my $self = shift;
    my %args = (
        files => [],
        cases => [],
        sets => [],
    );
    my $flag;
    for my $arg ( @ARGV ) {
        if ( $arg =~ m/^-(.*)$/) {
            $flag = $1;
            next
        }
        elsif ( $flag ) {
            my $ref = ref( $args{ $flag } ) || 'none';
            if( $ref eq 'ARRAY' ) {
                push @{ $args{ $flag }} => $arg;
            }
            else {
                $args{ $flag } = $arg;
            }
            undef( $flag );
            next;
        }
        push @{ $args{ files }} => $arg;
    }
    return %args;
}

1;
