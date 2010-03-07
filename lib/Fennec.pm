package Fennec;
use strict;
use warnings;

use Fennec::Test;
use Fennec::Test::Functions;
use Carp;

our $VERSION = "0.005";
our @DEFAULT_PRODUCERS = qw/Warn Exception More Simple/;

sub import {
    my $class = shift;
    my %options = @_;
    my ( $package, $filename ) = caller();

    croak( "Fennec runner has not yet been initialized" )
        unless $Fennec::Runner::SINGLETON;
    croak( "You must put your tests into a package, not main" )
        if $package eq 'main';
    croak( "$package is already a test class" )
        if Fennec::Runner->get->get_test( $package );

    # If a testing class is specified then load it and run import
    my $get_from = $options{ testing };
    eval "require $get_from" || croak( $@ ) if $get_from;
    if ( $get_from && !$get_from->isa(__PACKAGE__) && (my $sub = $get_from->can( 'import' ))) {
        my @args = @{ $options{ import_args } || []};

        # Sub::Uplevel was being wacky, this works fine.
        eval "
            package $package;
            use strict;
            use warnings;
            \$sub->(\$get_from, \@args)
        ";
    }

    # Test files automatically become objects.
    {
        no strict 'refs';
        push @{ $package . '::ISA' } => 'Fennec::Test';
    }

    # Export functions from producers, and for grouping
    $class->_export_producers( $package, $options{ producers } );
    Fennec::Test::Functions->export_to( $package );

    my $test = $package->new( %options, filename => $filename );
    Fennec::Runner->get->add_test( $test );
    return $test;
}

sub _export_producers {
    my $class = shift;
    my ( $package, $specs ) = @_;
    my @producers = @DEFAULT_PRODUCERS;

    # They may be requesting extra producers, or requesting the removal of
    # default ones.
    if ( $specs ) {
        my %remove;
        for ( @$specs ) {
            m/^-(.*)$/ ? ($remove{$1}++)
                       : (push @producers => $_);
        }

        my %seen;
        @producers = grep { !($seen{$_}++ || $remove{$_}) } @producers;
    }

    for my $producer ( @producers ) {
        my $name = "Fennec\::Producer\::$producer";
        eval "require $name" || die( $@ );
        $name->export_to( $package );
    }
}

1;

=pod

=head1 NAME

Fennec - A more modern testing framework for perl

=head1 DESCRIPTION

Fennec is a test framework that addresses several complains I have heard,
or have myself issued forth about perl testing. It is still based off
L<Test::Builder> and uses a lot of existing test tools.

Please see L<Fennec::Specification> for more details.

=head1 WHY FENNEC

Fennec is intended to do for perl testing what L<Moose> does for OOP. It makes
all tests classes, and defining test cases and test sets within that class is
simple. In traditional perl testing you would have to manually loop if you
wanted to run a set of tests multiple times in different cases, it is difficult
to make forking tests, and you have limited options for more advanced test
frameworks.

Fennec runs around taking care of the details for you. You simply need to
specify your sets, your cases, and weather or not you want the sets and cases
to fork, run in parrallel or in sequence. Test sets and cases are run in random
order by default. Forking should just plain work without worrying about the
details.

The Fennec fox is a hyper creature, it does a lot of running around, because of
this the name fits. As well Fennec is similar in idea to Moose, so why not name
it after another animal? Finally I already owned the namespace for a dead
project, and the namespace I wanted was taken.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 MANUAL

L<Fennec::Manual> - More detailed usage

=head1 SYNOPSYS

    package TEST::MyThing;
    use strict;
    use warnings;

    use fennec testing => 'MyThing';

    my $one;

    test_case a => sub {
        $one = MyThing->new( 'a' );
    };

    test_case b => sub {
        $one = MyThing->new( 'b' );
    };

    test_set first => sub {
        isa_ok( $one, 'MyThing' );
    };

    test_set first => sub {
        ok( $one->do_thing, "Thing was done" );
    };

    1;

=head1 EXPORTS

There are two functions exported by Fennec.

=over 4

=item test_case name => sub { ... }

=item test_case( $name, $code );

Define a test case. Every set defined will be run under each test case.

=item test_set name => sub { ... };

=item test_set( $name, $code );

Define a test set. Every set defined will be run under each test case.

=back

=head1 IMPORT

Fennec is the only module someone using Fennec should have to 'use'.
The parameters provided to import() on use do a significant portion of the test
setup. When Fennec is used it will instantate a singleton of your test
class and store it as a test to be run.

Using Fennec also automatically adds 'Fennec::Test' to your classes @ISA.

=head1 IMPORT OPTIONS

    use Fennec %OPTIONS;

These are the options supported, all are optional.

=over 4

=item testing => 'My::Module'

Used to specify the module to be tested by this test class. This module will be
loaded, and it's import will be run with the test class as caller. This is a
lot like use_ok(), the difference is that 'use' forces a BEGIN{} block.

Anything exported by the tested module will be loaded before the rest of the
test class is compiled. This allows the use of exported functions with
prototypes and the use of constants within the test class.

    use Fennec testing => 'My::Module';

=item import_args => [ @ARGS ]

Specify the arguments to provide the import() method of the module specified by
'testing => ...'.

    use Fennec testing => 'My::Module',
           import_args => [ 'a', 'b' ];

=item producers => [ 'want', 'another', '-do_not_want', '-this_either' ]

Specify which producers to load or prevent loading. By default 'More', 'Simple',
'Exception', and 'Warn' producers are loaded. You may specify any additional
producers. You may also prevent the loadign of a default producer by listing it
prefixed by a '-'.

See L<Fennec::Producer> for more information about producers.

See Also L<Fennec::Producer::Simple>, L<Fennec::Producer::More>,
L<Fennec::Producer::Exception>, L<Fennec::Producer::Warn>

=item all others

All other arguments will be passed into the constructor for your test class,
which is defined in L<Fennec::Test>.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
