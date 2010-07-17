package Fennec::Assert::Core::Simple;
use strict;
use warnings;

use Fennec::Util::Alias qw/
    Fennec::Output::Result
    Fennec::Output::BailOut
/;

use Fennec::Assert;
use Try::Tiny;
use Carp qw/cluck/;

util TODO => sub(&;$) {
    my ( $code, $reason ) = @_;
    $reason ||= "no reason given";
    Result->TODO( $reason );
    try {
        $code->();
    }
    catch {
        diag( "Caught error in todo block\n  Error: $_\n  todo: $reason" );
    };
    Result->TODO( undef );
};

util SKIP => sub(&;$) {
    my ( $code, $reason ) = @_;
    $reason ||= "no reason given";
    result(
        pass => 1,
        skip => $reason,
        name => "Anonymous Skip block",
    );
};

util diag => \&diag;

tester ok => sub {
    my ( $ok, $name ) = @_;
    result(
        pass => $ok ? 1 : 0,
        name => $name || 'nameless test',
    );
};

util bail_out => sub {
    BailOut->new( stderr => [@_] )->write;
};

1;

=pod

=head1 NAME

Fennec::Assert::Core::Simple - Assertion library that mirrors L<Test::Simple>'s
functionality.

=head1 DESCRIPTION

This assertion library exports testers nearly identical to those in
L<Test::Simple>. they should be almost completely compatible with
L<Test::Simple>'s.

=head1 TESTERS

These are exported for use within tests, each one generates at least 1 result.

=over 4

=item ok($bool; $name)

Generates a pass result if $bool is true, fail if $bool is false, $name is
optional but recommended.

=back

=head1 UTILS

These utils are exported in addition to the testers, they do not produce any
results.

=over 4

=item bail_out( @reasons )

Tell fennec to stop everything, somethings wrong, just stop.

=item TODO(sub { ... }; $reason)

=item TODO { ... } $reason

=item TODO { ... }

Run the code block, any results generated within will be marked as todo. This
means any failures will not lead to an overall suite failure.

=item diag( @messages )

Generate a diagnostics message.

=back

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
