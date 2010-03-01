package Test::Suite::TestBuilderImposter;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

Test::Suite::TestBuilderImposter - Override parts of Test::Builder.

=head1 DESCRIPTION

This package loads L<Test::Builder> and overrides parts of it so that outside
test utilities can be wrapped and don't interfere with L<Test::Suite>.

=head1 EARLY VERSION WARNING

This is VERY early version. Test::Suite does not run yet.

Please go to L<http://github.com/exodist/Test-Suite> to see the latest and
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
        $Test::Suite::Plugin::TB_USED++;
        $TBI_RESULT = [ $ok, $name ];
    },
    diag => sub {
        shift;
        $Test::Suite::Plugin::TB_USED++;
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

Test-Suite is free software; Standard perl licence.

Test-Suite is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
