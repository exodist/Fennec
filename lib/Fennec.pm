package Fennec;
use strict;
use warnings;

use Carp;
use Fennec::Runner;
use Fennec::Test;
use Fennec::Test::Functions;

our $VERSION = "0.010";
our $TEST_CLASS;

sub clear_test_class { $TEST_CLASS = undef }
sub test_class { $TEST_CLASS }

sub import {
    my $class = shift;
    my %proto = @_;
    my ( $caller, $file, $line ) = caller;
    my ( $groups, $generators ) = @proto{qw/ groups generators /};
    my $standalone = delete $proto{ standalone };

    if ( $standalone and !Runner ) {
        'Fennec::Runner'->init(
            %$standalone,
            files => [ $caller ],
            filetypes => [ 'Standalone' ]
        );
        no strict 'refs';
        *{ $caller . '::start' } = sub { Runner->start };
    }

    croak "Test runner not found"
        unless Runner;
    croak( "You must put your tests into a package, not main" )
        if $caller eq 'main';

    $TEST_CLASS = $caller;

    {
        no strict 'refs';
        push @{ $caller . '::ISA' } => Test;
    }

    $groups ||= [ qw/Tests/ ];
    my $functions = Functions->new( @$groups );
    $functions->export_to( $caller );

    $generators ||= [ qw/ Simple / ];
    export_package_to( 'Fennec::Generator::' . $_, $caller )
        for @$generators;

    1;
}

sub export_package_to {
    my ( $from, $to ) = @_;
    eval "require $from; 1" || die( $@ );
    $from->export_to( $to );
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
