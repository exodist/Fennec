package Fennec::Generator::Simple;
use strict;
use warnings;

use Fennec::Generator;
use Fennec::Result;
use Try::Tiny;

export ok => sub {
    my ( $ok, $name ) = @_;
    result(
        pass => $ok ? 1 : 0,
        name => $name || 'nameless test',
    );
}

export todo => sub(&;$) {
    my ( $code, $reason ) = @_;
    Result->TODO( $reason || "no reason given" );
    try {
        $code->();
    }
    catch {
        diag( "Caught error in todo block\n  Error: $_\n  todo: $reason" );
    }
    Result->TODO( undef );
}

export diag => \&diag;

export 'require_ok';
sub require_ok(*) {
    my ( $package ) = @_;
    try {
        eval "require $package" || die( $@ );
    }
    catch {
        result(
            pass => 0,
            name => "require $package",
            diag => [ $_ ],
        );
    }
    result(
        pass => 1,
        name => "require $package",
    );
}

export 'use_into_ok';
sub use_into_ok(**;@) {
    my ( $from, $to, @importargs ) = @_;
    require_ok( $from );
    my $run = "package $to; $from->import";
    $run .= '(@_)' if @importargs;
    try {
        eval $run || die( $@ );
    }
    catch {
        result(
            pass => 0,
            name => "$from\->import(...)",
            diag => [ $_ ],
        );
    }
    result(
        pass => 1,
        name => "$from\->import(...)",
    );
}

export use_ok(*) {
    my( $from, @importargs ) = @_;
    my $caller = caller;
    use_into_ok( $from, $caller, @importargs );
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
