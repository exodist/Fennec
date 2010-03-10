package Fennec::Runner::Args;
use strict;
use warnings;

our @EXPORT = qw/parse_args/;
use base 'Exporter';

sub parse_args {
    my @argv = @_;
    my %args = (
        files => [],
        c => [],
        s => [],
        I => [],
    );
    $args{ cases } = \@{$args{ c }};
    $args{ sets } = \@{$args{ s }};

    my $flag;
    for my $arg ( @argv ) {
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

    delete $args{ c };
    delete $args{ s };
    my $files;
    if (@{$args{ files }}) {
        $files = Fennec::Files->new_from_list( delete $args{ files } );
    }

    return ( %args, $files ? (files => $files) : ( files => undef ));
}

