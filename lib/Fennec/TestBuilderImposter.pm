package Fennec::TestBuilderImposter;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Fennec::TestBuilderImposter - Override parts of Test::Builder.

=head1 DESCRIPTION

This package loads L<Test::Builder> and overrides parts of it so that outside
test utilities can be wrapped and don't interfere with L<Fennec>.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=cut

#}}}

use Test::Builder;

1;

package Test::Builder;
use strict;
use warnings;

our $TBI_RESULT;
our @TBI_DIAGS;

our %OVERRIDE = (
    ok => sub {
        shift;
        my ( $ok, $name ) = @_;
        $Fennec::Plugin::TB_USED++;
        $TBI_RESULT = [ $ok, $name ];
    },
    diag => sub {
        shift;
        $Fennec::Plugin::TB_USED++;
        push @TBI_DIAGS => @_;
    },
);

for my $ref (keys %OVERRIDE) {
    no warnings 'redefine';
    no strict 'refs';
    my $newref = "real_$ref";
    *$newref = \&$ref;
    *$ref = $OVERRIDE{ $ref };
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
