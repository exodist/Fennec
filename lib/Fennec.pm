package Fennec;
use strict;
use warnings;
use Data::Dumper;

sub import {
    my $class = shift;
    my %args = @_;
    $args{-base} ||= 'Fennec::Base';
    my @caller = caller;

    if ( $0 eq $caller[1] ) {
        $ENV{PERL5LIB} = join( ':', @INC );
        exec "$^X -MFennec::Runner -e 'Fennec::Runner::run_file(\"$0\")'";
    }
    require Fennec::Runner;
    no warnings 'once';
    push @Fennec::Runner::TEST_CLASSES => (caller)[0];

    no strict 'refs';
    eval "require $args{-base}" || die $@;
    push @{"$caller[0]\::ISA"} => $args{-base};
    *{"$caller[0]\::tests"} = sub { $_[1]->() };
}

1;
