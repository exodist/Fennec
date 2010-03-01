package Test::Suite::TestHelper;
use strict;
use warnings;
use Test::Suite::TestBuilderImposter;

=pod

=head1 NAME

Test::Suite::TestHelper - Make Test::Suite testable

=head1 DESCRIPTION

Prevents plugins from producing TAP output and instead provides you with
results that would be sent to Test::Suite.

=head1 SYNOPSYS

    #!/usr/bin/perl
    use Test::Suite::TestHelper;
    use warnings;
    use strict;
    use Test::More;
    use Data::Dumper;

    # Should be in a BEGIN to make testers with prototypes work.
    BEGIN {
        real_tests { use_ok( 'MyPlugin' ) };
        MyPlugin->export_to( __PACKAGE__ );
    }

    my_tester( ... );
    my_other_tester( ... );

    my $results = results();

    # Actual tests that should produce output must be in a 'real_tests' block.
    real_tests {
        ok( @$results, "found results" );
    };

A single result will follow this format

    {
        # These are reliable.
        result => $TEST_RESULT, # what your custom tester returned
        name   => $TEST_NAME,   # The second item your custom tester returned
        time   => $RUN_TIME,    # How long the test took to run (Timer::HiRes)
        debug  => \@DEBUG,      # If the test failed this should contain
                                # extra information that should be printed for
                                # the user (This is all the other elements your
                                # custom tester returned)

        # These should be reliable
        package  => $PACKAGE,   # Package the test was run from
        filename => $FILENAME,  # Filename test was run from
        line     => $LINE,      # Line number where test was run

        # These may or may not be defined
        todo => $REASON,        # If the test was run in a todo {} block.

        # If run under a set/case these will be references to the case/set objects
        case => $CASE,
        set => $SET,
    }

=head1 EXPORTS

=over 4

=item $results = results()

=item results(1)

Returns an arrayref with all the results obtained since results was last
cleared. Optional argument tells results() to clear all results.

=back

=head1 MAGIC BE HERE

This works by overriding parts of L<Test::Suite::Plugin> so that when called
parts of Test::Suite are lexically overriden. There is all kinds of room from
problems here, but I am not sure of a better way yet, just be careful.

=cut

our @EXPORT = qw/results diags real_tests/;
use base 'Exporter';

our $RESULTS = [];
our $DIAG = [];

sub results {
    $RESULTS = [] if @_;
    return $RESULTS;
}

sub diags {
    $DIAG = [] if @_;
    return $DIAG;
}

sub push_diag {
    push @$DIAG => @_;
}

sub real_tests(&) {
    my ( $sub ) = @_;

    no warnings 'redefine';
    local *Test::Builder::ok = \&Test::Builder::real_ok;
    local *Test::Builder::diag = \&Test::Builder::real_diag;

    return $sub->();
}

require Test::Suite::Plugin;

{
    no strict 'refs';
    no warnings 'redefine';
    my $old = \&{ 'Test::Suite::Plugin::_record' };
    *{ 'Test::Suite::Plugin::_record' } = sub {
        local *{ 'Test::Suite::get' } = sub { 'Test::Suite' };
        local *{ 'Test::Suite::result' } = sub {
            shift;
            push @$RESULTS => @_;
        };
        local *{ 'Test::Suite::diag' } = sub {
            shift;
            push @$DIAG => @_;
        };
        return $old->( @_ );
    };
}

1;

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
