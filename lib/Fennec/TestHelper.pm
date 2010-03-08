package Fennec::TestHelper;
use strict;
use warnings;
use Fennec::Runner;
use Fennec::Interceptor;

#XXX TODO With the addition of output plugins this can probably be greatly reduced. This should probably boil donw to real_tests() and leave the rest to an output plugin like Output::Test.

our @EXPORT = qw/results diags real_tests push_diag/;
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
    local *Test::Builder::real_done_testing = \&Test::Builder::done_testing;
    local *Test::Builder::done_testing = sub {1};

    return $sub->();
}

require Fennec::Tester;

{
    no strict 'refs';
    no warnings 'redefine';
    my $old = \&{ 'Fennec::Tester::_result' };
    *{ 'Fennec::Tester::_result' } = sub {
        local *{ 'Fennec::Runner::result' } = sub {
            shift;
            push @$RESULTS => @_;
        };
        local *{ 'Fennec::Runner::diag' } = sub {
            shift;
            push @$DIAG => @_;
        };
        return $old->( @_ );
    };
}

1;

__END__

=pod

=head1 NAME

Fennec::TestHelper - Make Fennec testable

=head1 DESCRIPTION

Prevents plugins from producing TAP output and instead provides you with
results that would be sent to Fennec.

=head1 SYNOPSYS

    #!/usr/bin/perl
    use Fennec::TestHelper;
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

=head1 EXPORTED FUNCTIONS

=over 4

=item $results = results()

=item results(1)

Returns an arrayref with all the results obtained since results was last
cleared. Optional argument tells results() to clear all results.

=item $diags = diags()

=item diags(1)

Returns an arrayref with all diags issued since diags were last cleared.
Optional argument will clear the list.

=item push_diags( @messages )

Add messages to diags.

=item real_tests( $code )

Run tests with normal L<Test::Builder>. This is where your tests actually work
as tests.

=back

=head1 MAGIC BE HERE

This works by overriding parts of L<Fennec::Tester> so that when called
parts of Fennec are lexically overriden. There is all kinds of room from
problems here, but I am not sure of a better way yet, just be careful.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
