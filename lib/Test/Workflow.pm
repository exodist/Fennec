package Test::Workflow;
use strict;
use warnings;

use Exporter::Declare;
use Test::Workflow::Meta;
use Test::Workflow::Test;
use Test::Workflow::Layer;
use List::Util qw/shuffle/;

default_exports qw/
    tests       run_tests
    describe    it
    cases       case
    before_each after_each around_each
    before_all  after_all  around_all
    with_tests
    test_sort
/;

gen_default_export TEST_WORKFLOW => sub {
    my ( $class, $importer ) = @_;
    my $meta = Test::Workflow::Meta->new($importer);
    return sub { $meta };
};

{ no warnings 'once'; @DB::CARP_NOT = qw/ DB Test::Workflow /}
sub _get_layer {
    package DB;
    use Carp qw/croak/;
    use Scalar::Util qw/blessed/;

    my ($sub, $caller) = @_;

    my @parent = caller(2);
    my @pargs = @DB::args;
    my $layer = $pargs[-1];

    if ( blessed($layer) && blessed($layer)->isa( 'Test::Workflow::Layer' )) {
        croak "Layer has already been finalized!"
            if $layer->finalized;
        return $layer;
    }

    my $meta = $caller->[0]->TEST_WORKFLOW;
    croak "$sub() can only be used within a describe or case block, or at the package level. (Could not find layer, did you modify \@_?)"
        if $meta->build_complete;

    return $meta->root_layer;
}

sub with_tests  { my @caller = caller; _get_layer( 'with_tests', \@caller )->merge_in( \@caller, @_ )}

sub tests { my @caller = caller; _get_layer( 'tests', \@caller )->add_test( \@caller, @_, 'verbose' )}
sub it    { my @caller = caller; _get_layer( 'it',    \@caller )->add_test( \@caller, @_, 'verbose' )}
sub case  { my @caller = caller; _get_layer( 'case',  \@caller )->add_case( \@caller, @_ )}

sub describe { my @caller = caller; _get_layer( 'describe', \@caller )->add_child( \@caller, @_ )}
sub cases    { my @caller = caller; _get_layer( 'cases',    \@caller )->add_child( \@caller, @_ )}

sub before_each { my @caller = caller; _get_layer( 'before_each', \@caller )->add_before_each( \@caller, @_ )}
sub before_all  { my @caller = caller; _get_layer( 'before_all',  \@caller )->add_before_all(  \@caller, @_ )}
sub after_each  { my @caller = caller; _get_layer( 'after_each',  \@caller )->add_after_each(  \@caller, @_ )}
sub after_all   { my @caller = caller; _get_layer( 'after_all',   \@caller )->add_after_all(   \@caller, @_ )}
sub around_each { my @caller = caller; _get_layer( 'around_each', \@caller )->add_around_each( \@caller, @_ )}
sub around_all  { my @caller = caller; _get_layer( 'around_all',  \@caller )->add_around_all(  \@caller, @_ )}

sub test_sort { caller->TEST_WORKFLOW->test_sort( @_ )}

sub run_tests {
    my ( $instance ) = @_;
    my $layer = $instance->TEST_WORKFLOW->root_layer;
    $instance->TEST_WORKFLOW->build_complete(1);
    my @tests = get_tests( $instance, $layer, [], [], [] );
    my $sort = $instance->TEST_WORKFLOW->test_sort || 'rand';
    @tests = sort @tests if "$sort" =~ /^sort/;
    @tests = shuffle @tests if "$sort" =~ /^rand/;
    @tests = $sort->( @tests ) if ref $sort eq 'CODE';
    $_->run( $instance ) for @tests;
}

sub get_tests {
    my ( $instance, $layer, $before_each, $after_each, $around_each ) = @_;
    # get before_each and after_each
    push    @$before_each => @{ $layer->before_each };
    push    @$around_each => @{ $layer->around_each };
    unshift @$after_each  => @{ $layer->after_each  };

    my @tests = map { Test::Workflow::Test->new(
        setup    => [ @$before_each ],
        tests    => [ $_            ],
        teardown => [ @$after_each  ],
        around   => [ @$around_each ],
    )} @{ $layer->test };

    my @cases = @{ $layer->case };
    if ( @cases ) {
        @tests = map {
            my $test = $_;
            map { Test::Workflow::Test->new(
                setup => [ $_    ],
                tests => [ $test ],
            )} @cases
        } @tests;
    }

    push @tests => map {
        my $layer = Test::Workflow::Layer->new;
        $_->run( $instance, $layer );
        warn "No tests in block '" . $_->name . "' approx lines " . $_->start_line . "->" . $_->end_line . "\n"
            unless @{ $layer->test };
        get_tests( $instance, $layer, $before_each, $after_each, $around_each );
    } @{ $layer->child };

    my @before_all = @{ $layer->before_all };
    my @after_all  = @{ $layer->after_all  };
    my @around_all = @{ $layer->around_all };
    return Test::Workflow::Test->new(
        setup    => [ @before_all ],
        tests    => [ @tests      ],
        teardown => [ @after_all  ],
        around   => [ @around_all ],
    ) if @before_all || @after_all || @around_all;

    return @tests;
}

1;
