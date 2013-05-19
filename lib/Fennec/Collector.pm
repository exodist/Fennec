package Fennec::Collector;
use strict;
use warnings;

use Carp qw/confess/;
use Fennec::Util qw/accessors require_module/;

accessors qw/test_count test_failed/;

sub ok      { confess "Must override ok" }
sub diag    { confess "Must override diag" }
sub end_pid { confess "Must override end_pid" }
sub collect { confess "Must override collect" }

sub finish { }
sub init   { }

sub new {
    my $class  = shift;
    my %params = @_;
    my $self   = bless \%params, $class;
    $self->init;

    return $self;
}

sub inc_test_count {
    my $self = shift;
    my $count = $self->test_count || 0;
    $self->test_count( $count + 1 );
}

sub inc_test_failed {
    my $self = shift;
    my $count = $self->test_failed || 0;
    $self->test_failed( $count + 1 );
}

1;

__END__

=head1 NAME

Fennec::Collector - Funnel results from child to parent

=head1 DESCRIPTION

The collector is responsible for 2 jobs:
1) In the parent process it is responsible for gathering all test results from
the child processes.
2) In the child processes it is responsbile for sending results to the parent
process.

=head1 METHODS SUBCLASSES MUST OVERRIDE

=over 4

=item $bool = ok( $bool, $description )

Fennec sometimes needs to report the result of an internal check. These checks
will pass a boolean true/false value and a description.

=item diag( $msg )

Fennec uses this to report internal diagnostics messages

=item end_pid

Called just before a child process exits.

=item collect

Used by the parent process at an interval to get results from children and
display them.

=back

=head1 METHODS SUBCLASSES MAY OVERRIDE

=over 4

=item new

Builds the object from params, then calls init.

=item init

Called by new

=item finish

Called at the very end of C<done_testing()> no tests should be reported after
this.

=back

=head1 METHODS SUBCLASSES MUST BE AWARE OF

=over 4

=item test_count

Holds the test count so far.

=item test_failed

Holds the number of tests failed so far.

=item inc_test_count

Used to add 1 to the number of tests.

=item inc_test_failed

Used to add 1 to the number of failed tests.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license (GPL and Artistic).

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
