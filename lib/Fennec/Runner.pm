package Fennec::Runner;
use strict;
use warnings;
our $TBOUT;

BEGIN {
    if ( eval { require Test::Builder; 1 }) {
        open( my $Testout, '>', \$TBOUT ) || die $!;
        my $old_fh = select $Testout; $| = 1; select $old_fh;

        no warnings 'redefine';
        *Test::Builder::reset_outputs = sub {
            my $self = shift;
            $self->output        ($Testout);
            $self->failure_output($Testout);
            $self->todo_output   ($Testout);
            return;
        };

        Test::Builder->new->reset_outputs;
    }

    if ( $0 eq '-e' ) {
        my %seen;
        @INC = grep { !$seen{$_}++ } @INC;
    }
}

our @TEST_CLASSES;

sub run_file {
    my $file = shift;
    eval { require $file } || die $@;
    run();
}

sub run_module {
    my $module = shift;
    eval "require $module" || die $@;
    run();
}

sub run {
    while( my $class = shift( @TEST_CLASSES )) {
        $class->new->run;
    }
    $TBOUT =~ s/^([^#])/# $1/gm;
    print STDERR $TBOUT;
}

1;
