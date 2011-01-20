package Fennec;
use strict;
use warnings;

use Fennec::Util qw/inject_sub/;

our $VERSION = '0.100';

sub defaults {(
    utils => [qw/
        Test::More Test::Warn Test::Exception Test::Workflow
    /],
    utils_with_args => {
    },
    parallel => 0,
    runner => 'Fennec::Runner',
)}

sub init {}

sub import {
    my $class = shift;
    my @caller = caller;
    my %defaults = $class->defaults;
    $defaults{runner} ||= 'Fennec::Runner';

    # If the Fennec test file was run directly we need to re-run perl and run the
    # test file through Fennec::Runner. The alternative is an END block.
    if ( $0 eq $caller[1] ) {
        $ENV{PERL5LIB} = join( ':', @INC );
        exec "$^X -M$defaults{runner} -e '" . <<"        EOT";
            our \$runner;
            BEGIN {
                \$runner = Fennec::Runner->new;
                \$runner->load_file(\"$0\")
            }
            \$runner->run();'
        EOT
    }

    my %params = ( %defaults, @_ );
    my $importer = $caller[0];
    Fennec::Runner->new->test_classes_push( $importer );

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
