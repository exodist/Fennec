package Fennec::Assert::TBCore;
use strict;
use warnings;

our @CORE_LIST = qw/More Exception Warn/;

sub export_to {
    my $class = shift;
    my ( $dest, $prefix ) = @_;
    for my $item ( map { 'Fennec::Assert::TBCore::' . $_ } @CORE_LIST ) {
        eval "require $item; 1" || die ($@);
        $item->export_to( $dest, $prefix );
    }
}

sub import {
    my $class = shift;
    my ( $prefix ) = @_;
    my $caller = caller;
    $class->export_to( $caller, $prefix );
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
