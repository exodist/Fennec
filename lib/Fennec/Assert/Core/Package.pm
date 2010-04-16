package Fennec::Assert::Core::Package;
use strict;
use warnings;

use Fennec::Util::Alias qw/
    Fennec::Output::Result
/;

use Fennec::Assert;
use Try::Tiny;
use Carp qw/cluck/;

tester 'require_ok';
sub require_ok(*) {
    my ( $package ) = @_;
    try {
        eval "require $package" || die( $@ );
        result(
            pass => 1,
            name => "require $package",
        );
    }
    catch {
        result(
            pass => 0,
            name => "require $package",
            stderr => [ $_ ],
        );
    };
};

tester 'use_into_ok';
sub use_into_ok(**;@) {
    my ( $from, $to, @importargs ) = @_;
    my $run = "package $to; $from->import";
    $run .= '(@_)' if @importargs;
    try {
        eval "require $from; 1" || die( $@ );
        eval "$run; 1" || die( $@ );
        result(
            pass => 1,
            name => "$from\->import(...)",
        );
    }
    catch {
        return result(
            pass => 0,
            name => "$from\->import(...)",
            stderr => [ $_ ],
        );
    }
};

tester use_ok => sub(*) {
    my( $from, @importargs ) = @_;
    my $caller = caller;
    use_into_ok( $from, $caller, @importargs );
};

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
