package Fennec::Util::Abstract;
use strict;
use warnings;

use Carp;

sub import {
    my $class = shift;
    my $caller = caller;

    no strict 'refs';
    *{ $caller . '::Abstract' } = sub {
        for my $accessor ( @_ ) {
            *{ $caller . '::' . $accessor } = sub {
                die( "$caller does not implement $accessor()" );
            };
        }
    };
}

1;

=head1 NAME

Fennec::Util::Abstract - Provides the 'Abstract()' method.

=head1 DESCRIPTION

Provides the 'Abstract()' method, which can be used inside an abstract method
to die with an explanation.

=head1 SYNOPSIS

    package MyPackage;
    use Fennec::Util::Abstract;

    sub do_thing { Abstract() }

    1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
