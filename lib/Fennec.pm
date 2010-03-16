package Fennec;
use strict;
use warnings;

use Carp;
use Fennec::Runner;
use Fennec::Test;
use Fennec::Test::Function;
use Fennec::Generator;

our $VERSION = "0.006";
our $TEST_CLASS;

sub clear_test_class { $TEST_CLASS = undef }
sub test_class { $TEST_CLASS }

sub import {
    my $class = shift;
    my %proto = @_;
    my ( $caller, $file, $line ) = caller;
    my ( $load, $functions, $generators ) = @proto{qw/ load functions generators /}

    croak "Test runner not found"
        unless Runner;
    croak( "You must put your tests into a package, not main" )
        if $caller eq 'main';

    $TEST_CLASS = $caller;

    {
        no strict 'refs';
        push @{ $caller . '::ISA' } => Test;
    }

    $functions ||= [ qw/ Tests Spec Case / ];
    $generators ||= [ qw/ Simple More Warn Exception / ];

    load_to_package( $load, $caller ) if $load;

    export_package_to( 'Fennec::Test::Function::' . $_, $caller )
        for @$functions;

    export_package_to( 'Fennec::Generator::' . $_, $caller )
        for @$generators;

    1;
}

sub export_package_to {
    my ( $from, $to ) = @_;
    eval "require $from; 1" || die( $@ );
    $from->export_to( $to );
}

sub load_to_package {
    my ( $load, $package ) = @_;
    $load = { map { $_ => [] } @$load }
        if ref( $load ) eq 'ARRAY';

    for my $want ( keys %$load ) {
        my @args = @{ $load->{ $want }};
        # Sub::Uplevel was being wacky, this works fine.
        eval "
            package $package;
            use strict;
            use warnings;
            require $want;
            \@args ? $want\->import( \@args );
                   : $want\->import;
            1;
        " || die( $@ );
    }
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
