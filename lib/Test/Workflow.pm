package Test::Workflow;
use strict;
use warnings;

use Exporter::Declare;
use Test::Workflow::Meta;

default_exports qw/
    tests       run_tests
    describe    it
    cases       case
    before_each after_each
    before_all  after_all
    with_tests
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

    my ($caller) = @_;

    my @parent = caller(2);
    my @pargs = @DB::args;
    my $state = $pargs[-1];

    return $state if blessed($state)
                  && blessed($state)->isa( 'Test::Workflow::State' );

    my $meta = $caller->[0]->TEST_WORKFLOW;
    croak "Could not find state, did you modify \@_?"
        if $meta->build_complete;

    return $meta->ROOT_LAYER;
}

sub with_tests  { my @caller = caller; _get_layer( \@caller )->merge_in( \@caller, @_ )}

sub tests { my @caller = caller; _get_layer( \@caller )->add_test( \@caller, @_ )}
sub it    { my @caller = caller; _get_layer( \@caller )->add_test( \@caller, @_ )}
sub case  { my @caller = caller; _get_layer( \@caller )->add_case( \@caller, @_ )}

sub describe { my @caller = caller; _get_layer( \@caller )->add_child( \@caller, @_ )}
sub cases    { my @caller = caller; _get_layer( \@caller )->add_child( \@caller, @_ )}

sub before_each { my @caller = caller; _get_layer( \@caller )->add_before_each( \@caller, @_ )}
sub before_all  { my @caller = caller; _get_layer( \@caller )->add_before_all(  \@caller, @_ )}
sub after_each  { my @caller = caller; _get_layer( \@caller )->add_after_each(  \@caller, @_ )}
sub after_all   { my @caller = caller; _get_layer( \@caller )->add_after_all(   \@caller, @_ )}

sub run_tests {
    my ( $instance ) = @_;
    my $layer = $instance->TEST_WORKFLOW->ROOT_LAYER;
    my @tests = get_tests( $instance, $layer );

}

1;
