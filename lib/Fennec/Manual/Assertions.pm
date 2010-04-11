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

=head1 TESTERS

=head1 UTILS

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
