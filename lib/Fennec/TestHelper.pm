package Fennec::TestHelper;
use strict;
use warnings;
use Fennec::Runner;
use Fennec::Interceptor;

our @EXPORT = qw/results diags push_diag push_results failures push_failures capture_tests/;
use base 'Exporter';

our @RESULTS;
our @DIAG;
our @FAILURES;
our @OUTPUT_HANDLERS;

sub results {
    @RESULTS = () if @_;
    return \@RESULTS;
}

sub diags {
    @DIAG = () if @_;
    return \@DIAG;
}

sub failures {
    @FAILURES = () if @_;
    return \@FAILURES;
}

sub push_diag {
    push @DIAG => @_;
}

sub push_results {
    push @DIAG => @_;
}

sub push_failures {
    push @FAILURES => @_;
}

# When things are run under capture_test results should go to @RESULTS, diag should go to @DIAG
sub capture_tests(&) {
    my ( $sub ) = @_;

    # Replace output handlers with ours. # localize?
    # Replace runner->failures with our own list # localize?

    return $sub->();

    # restore output handlers.
    # restore runner->failures.
}

1;

__END__

=pod

=head1 NAME

Fennec::TestHelper - Make Fennec testable

=head1 DESCRIPTION


=head1 SYNOPSYS


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

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
