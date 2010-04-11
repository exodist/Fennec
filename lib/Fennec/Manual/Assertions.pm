package Fennec::Manual::Assertions;
use strict;
use warnings;

1;

__END__

=head1 NAME

Fennec::Manual::Assertions - Writing Custom Assertion Libraries

=head1 SYNOPSYS

    package Fennec::Assert::MyAssert;
    use strict;
    use warnings;

    use Fennec::Assert;

    tester my_ok => sub {
        my ( $ok, $name ) = @_;
        result(
            pass => $ok ? 1 : 0,
            name => $name || 'nameless test',
        );
    };

    tester 'my_is';
    sub my_is {
        my ( $want, $got, $name ) = @_;
        my $ok = $want eq $got;
        result(
            pass => $ok,
            name => $name || 'nameless test',
        );
    }

    util 'my_util' => sub {
        ...
    };

    1;

=head1 STARTING

This is the only boilerplate:

    use Fennec::Assert;

This will add make your class a subclass of 'Fennec::Assert'.

This will also give you the following functions:

=over 4

=item tester($name; $sub)

Export a tester function

=item util($name; $sub)

Export a util function

=item result( pass => $p, name => $n, %result_props )

Generate a result

=item diag( @messages )

Produce diagnostics output (stderr)

=item $wrapped_sub = tb_wrapper($sub)

Wrap a Test::Builder based function to group a result and its diagnostics.

=item my %file_and_line = test_caller()

Returns ( line => $num, file => $file ) containing the line number and filename
of the first Fennec::TestFile in the caller stack. Useful to make sure you
report the correct line and filename in the test file being run.

=back

=head1 EXPORTS

An assert library is basically a package that exports functions for use within
tests. There are 2 types of export: tester, and util. Exports are defined by
calling the tester() or util() functions with a name and optional coderef.

L<Exporter::Declare> is used for the exporting, as such you do not need to
think about it beyond calling tester() and util().

=head1 TESTERS

Tester functions are functions you export using the tester() function. Your
function will be wrapped inside another function that provides extra
information such as diagnostics, benchmarking, and scope/caller information to
generated results.

The wrapper function will be defined with the same prototype as the function
being wrapped. If the original was defined as sub($$) {...} then $newsub will
also have the ($$) prototype.

=over 4

=item tester( 'name' )

=item tester( name => sub { ... })

In the first form you export a package sub as a tester by name. In the second
form you create a new export with an anonymous sub.

=back

=head1 UTILS

Utility functions are not wrapped like tester functions are, this means no free
diagnostics, scope, or caller. However unlike tester() a util can produce any
number of results, or no results at all.

=over 4

=item util( 'name' )

=item util( name => sub { ... })

In the first form you export a package sub as a util by name. In the second
form you create a new export with an anonymous sub.

=back

=head1 EARLY VERSION WARNING

L<Fennec> is still under active development, many features are untested or even
unimplemented. Please give it a try and report any bugs or suggestions.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
