package Fennec::Util::TBOverride;
use strict;
use warnings;

our %TB_OVERRIDES = (
    _ending => sub {},
    _my_exit => sub {},
    exit => sub {},
    plan => sub {},
    ok => sub {
        shift;
        my ( $ok, $name ) = @_;
        return Fennec::Assert::result(
            Fennec::Assert::test_caller(),
            pass => $ok,
            name => $name,
        ) unless $Fennec::Assert::TB_OK;
        $Fennec::Assert::TB_RESULT = [ $ok, $name ];
    },
    diag => sub {
        shift;
        return if $_[0] =~ m/No tests run!/;
        return Fennec::Assert::diag( @_ ) unless $Fennec::Assert::TB_OK;
        push @Fennec::Assert::TB_DIAGS => @_;
    },
    note => sub {
        shift;
        return Fennec::Assert::note( @_ ) unless $Fenec::Assert::TB_OK;
        push @Fennec::Assert::TB_NOTES => @_;
    }
);

if ( eval { require Test::Builder; 1 }) {
    Test::Builder->new->plan('no_plan');
    for my $ref (keys %TB_OVERRIDES) {
        no warnings 'redefine';
        no strict 'refs';
        my $newref = "real_$ref";
        *{ 'Test::Builder::' . $newref } = \&$ref;
        *{ 'Test::Builder::' . $ref    } = $TB_OVERRIDES{ $ref };
    }
}
if ( eval { require Test::More; 1 }) {
    no warnings 'redefine';
    no strict 'refs';
    my $export = \@{ 'Test::More::EXPORT' };
    @$export = grep { $_ ne 'done_testing' } @$export;
}

1;
