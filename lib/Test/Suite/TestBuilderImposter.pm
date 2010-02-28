package Test::Suite::TestBuilderImposter;
use strict;
use warnings;
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
