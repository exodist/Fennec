package Fennec;
use strict;
use warnings;

use Fennec::Tester;
use Fennec::Grouping;
use Fennec::Test;
use Carp;

our $VERSION = "0.005";
our @DEFAULT_PLUGINS = qw/Warn Exception More Simple/;

sub import {
    my $class = shift;
    my %options = @_;
    my ( $package, $filename ) = caller();

    if ( my $get_from = $options{ testing }) {
        eval "require $get_from" || croak( $@ );

        my $sub = $get_from->can('import');
        next unless $sub;

        my @args = @{ $options{ import_args } || []};

        # Sub::Uplevel was being wacky, this is easier
        eval "
            package $package;
            use strict;
            use warnings;
            \$sub->(\$get_from, \@args)
        ";
    }

    {
        no strict 'refs';
        push @{ $package . '::ISA' } => 'Fennec::Test';
    }

    $class->_export_plugins( $package, $options{ plugins } );
    Fennec::Grouping->export_to( $package );

    my $test = $package->new( %options, filename => $filename );
    Fennec::Tester->get->add_test( $test );
    return $test;
}

sub _get_import {
    my $class = shift;
    my ($get_from, $send_to) = @_;
    my $import = $get_from->can( 'import' );
    return unless $import;

    return ( 1, $import, $get_from )
        unless $get_from->isa( 'Exporter' );

    return ( 1, $import, $get_from )
        if $import != Exporter->can( 'import' );

    return ( 0, $get_from->can('export_to_level'), $get_from, 1, $send_to );
}

sub _export_plugins {
    my $class = shift;
    my ( $package, $specs ) = @_;
    my @plugins = @DEFAULT_PLUGINS;

    if ( $specs ) {
        my %remove;
        for ( @$specs ) {
            m/^-(.*)$/ ? ($remove{$1}++)
                       : (push @plugins => $_);
        }

        my %seen;
        @plugins = grep { !($seen{$_}++ || $remove{$_}) } @plugins;
    }

    for my $plugin ( @plugins ) {
        my $name = "Fennec\::Plugin\::$plugin";
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
wanted to runa set of tests multiple times in different cases, it is difficult
to make forking tests, and you have limited options for more advanced test
frameworks.

Fennec runs around taking care of the details for you. You simply need to
specify your sets, your cases, and weither or not you want the sets and cases
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
setup. When Fennec is used it will instantate a singleton of the calling
class and store it as a test to be run.

Using Fennec also automatically adds 'Fennec::Test' to the
calling classes @ISA.

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

    use Fennec testing     => 'My::Module',
                    import_args => [ 'a', 'b' ];

=item plugins => [ 'want', 'another', '-do_not_want', '-this_either' ]

Specify which plugins to load or prevent loading. By default 'More', 'Simple',
'Exception', and 'Warn' plugins are loaded. You may specify any additional
plugins. You may also prevent the loadign of a default plugin by listing it
prefixed by a '-'.

See L<Fennec::Plugin> for more information about plugins.

See Also L<Fennec::Plugin::Simple>, L<Fennec::Plugin::More>,
L<Fennec::Plugin::Exception>, L<Fennec::Plugin::Warn>

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
