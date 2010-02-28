package Test::Suite::PluginTester;
use strict;
use warnings;

=pod

=head1 NAME

Test::Suite::PluginTester - Easy testing of plugins

=head1 DESCRIPTION

Prevents plugins from producing TAP output and instead provides you with
results that would be sent to Test::Suite.

=head1 SYNOPSYS

    #!/usr/bin/perl
    use Test::Suite::PluginTester;
    use warnings;
    use strict;
    use Test::More;
    use Data::Dumper;

    use_ok( 'MyPlugin' );

    # Should be in a BEGIN to make testers with prototypes work.
    BEGIN { MyPlugin->export_to( __PACKAGE__ ) }

    my_tester( ... );
    my_other_tester( ... );

    my $results = results();

    for my $result ( @$results ) {
        print Dumper( $result );
    }

A single result will follow this format

    {
        # These are reliable.
        result => $TEST_RESULT, # what your custom tester returned
        name => $TEST_NAME,     # The second item your custom tester returned
        time => $RUN_TIME,      # How long the test took to run (Timer::HiRes)
        debug => \@DEBUG,       # If the test failed this should contain
                                # extra information that should be printed for
                                # the user (This is all the other elements your
                                # custom tester returned)

        # These should be reliable
        package => $PACKAGE,   # Package the test was run from
        filename => $FILENAME, # Filename test was run from
        line => $LINE,         # Line number where test was run
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

our @EXPORT = qw/results diags/;
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
