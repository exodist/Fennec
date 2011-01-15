package Fennec;
use strict;
use warnings;

# If the Fennec test file was run directly we need to re-run perl and run the
# test file through Fennec::Runner. The alternative is an END block.
BEGIN {
    if ( $0 eq (caller(2))[1] ) {
        $ENV{PERL5LIB} = join( ':', @INC );
        exec "$^X -MFennec::Runner -e 'BEGIN { Fennec::Runner::load_file(\"$0\")}; Fennec::Runner::run()'";
    }
}

use Fennec::Util qw/inject_sub/;

sub defaults {(
    utils => [qw/
        Test::More Test::Warn Test::Exception
    /],
        #Test::Workflow Test::Workflow::Spec Test::Workflow::Case
    parallel => 0,
)}

sub init {}

sub import {
    my $class = shift;
    my %params = @_;
    my @caller = caller;
    my $importer = $caller[0];
    Fennec::Runner->push_test_class( $importer );

    for my $require ( @{$params{skip_without} || []}) {
        die bless( "$require is not installed", 'Fennec::SKIP' )
            unless eval "require $require; 1";
    }

    require Fennec::Meta;
    my $meta = Fennec::Meta->new(
        fennec => $class,
        class => $importer,
        %params,
    );

    inject_sub( $importer, 'FENNEC', sub { $meta });

    my $base = $meta->base;
    if ( $base ) {
        no strict 'refs';
        eval "require $base" || die $@;
        push @{ "$importer\::ISA" } => $base
            unless grep { $_ eq $base } @{ "$importer\::ISA" };
    }

    for my $util ( @{ $meta->utils }) {
        my $code = "package $importer; require $util; $util\->import(\@{\$params{'$util'}}); 1";
        eval $code || die $@;
    }

    $class->init( %params, caller => \@caller, meta => $meta );
}

1;
