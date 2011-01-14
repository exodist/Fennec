package Fennec::Runner;
use strict;
use warnings;
use Carp qw/croak/;

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
        print "Running: $class\n";
    }
}

sub push_test_class {
    shift;
    push @TEST_CLASSES => @_;
}

1;
