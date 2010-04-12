package Fennec::Manual::Workflows;
use strict;
use warnings;

1;

__END__

=head1 NAME

Fennec::Manual::Workflows - Writing custom workflow plugins for Fennec.

=head1 EARLY VERSION WARNING

L<Fennec> is still under active development, many features are untested or even
unimplemented. Please give it a try and report any bugs or suggestions.

=head1 OVERVIEW

When a test file is loaded L<Fennec::Runner> creates a root workflow, this root
workflow is an L<Fennec::Workflow> object. Every testset or workflow defined in
the test file is defined in the form of a method. These methods are blessed to
the proper workflow or testset. The blessed methods are passed to the root
workflow.

When a child workflow method is executed it will be possitioned as 'current',
calling Fennec::Workflow->current will always return the current workflow, it
will throw an exception if there is no current workflow. You can nest testsets
and workflows by defining them inside a parent workflow method.

Example:

    package MyTest;
    use Fennec;

    # Export a function that is used to create an instance of the workflow.
    export my_workflow => sub {
        my ( $name, $sub ) = @_
        Fennec::Workflow->current->add_item(
            __PACKAGE__->new( $name, $sub )
        );
    };

    my_workflow parent => sub {
        tests 'parent tests' => {
            ...
        };
        my_workflow nested => sub {
            tests 'child tests' => {
                ...
            };
        };
    };

    1;

When Fennec runs it will load the file, it will create a root workflow, the
workflow sub named 'parent' will be blessed and passed to the root workflow as
a child workflow. Next Fennec will set 'parent' as the current workflow. The
workflow sub 'nested' will be blessed as a workflow and passed to 'parent' as a
child, it will then be set as current and executed.

Fennec will grab the testsets from the workflows after they have all been
traversed and executed. They will then optionally be randomized and executed.

The above example is fairly silly, There is no reason to put 'child tests'
within a child workflow. The only thing that makes nested workflows useful is
using L<Fennec::TestSet::SubSet> or writing your own subclass of
L<Fennec::TestSet> Doing so allows you to group tests, and add setup/teardown
functions, or do anything you can think of. The SubSet will be run in random
order with the other TestSets, however you can do whatever you want to the
tests grouped within.

=head1 CUSTOM WORKFLOW SYNOPSYS

    package Fennec::Workflow::MyWorkflow;
    use strict;
    use warnings;

    use Fennec::Workflow qw/:subclass/;

    # Code that should be executed just before running the tests
    build_hook { ... };

    # Method that returns an array of TestSet objects.
    sub testsets {
        my $self = shift;
            my $subset = SubSet->new(
                name => 'My Workflow Subset',
                workflow  => $self,
                file => $self->file,
            );
            $subset->add_setup( MySetup => sub { ... })
            $subset->add_testset( MyTest => sub { ... })
            $subset->add_teardown( MyTeardown => sub { ... })
    }

    # You should always provide line numbers for where your tests were defined.
    sub lines {
        my $self = shift;
        return 0 unless wantarray;
        my $subset = $self->testsets;
        return $subset->lines;
    }

    1;

=head1 METHODS THAT CAN BE OVERRIDEN

Overriding these is optional, not overriding them will result in a workflow
that acts just like the root workflow.

=over 4

=item @testsets = $wf->testsets()

testsets() should return an array with 0 or more testset objects or objects
that subclass testset. These will be run by Fennec in random order mixed with
other testsets from other workflows.

=item $wf->build()

The inherited method sets $wf as the current workflow, it then runs the method
that was blessed into as the workflow object. Overriding this is not
recommended, but may be necessary for some complicated workflows.

=item $wf->build_children()

This should rarely need to be overriden, calls $child->build() on all child
workflows. If you override add_items to add items other than workflows and
testsets, or to disallow adding items at all then you will probably want to
override this to reflect the change.

=item $wf->add_item( $item )

Add $item to the workflow. The inherited method will add workflows or testsets,
it will throw an exception for anything else.

=back

=head1 HELPFUL FUNCTIONS

=over 4

=item build_hook { ... }

=item build_hook( sub { ... })

Add code that should be run just after building the workflows and jus before
running the tests.

=back

=head1 OTHER METHODS TO KNOW

=over 4

=item import()

L<Fennec::Workflow> has a complicated import() method, in order to simplify it
all classes that sublcass L<Fennec::Workflow> have a new import() method
exported to their package. It is important that you do not try to override
import(), or that you are at least aware that you cannot call
$wf->SUPER::import() and get the expected behavior. Defining your own import()
method will also throw a redefine warning.

=item @wfs = $wf->workflows()

Returns a list of all the workflows added as children.

=item $tf = $wf->testfile()

Returns the L<Fennec::TestFile> object currently being run.

=item $pwf = $wf->parent()

Returns the parent workflow object to which this one is a child, the root
workflow will return the TestFile object.

=item $testsets = $wf->_testsets()

=item $wf->_testsets( \@testsets )

Get/Set the list of testsets, if you override add_item() and never caller
SUPER::add_item() then you will need to manually add TestSets to the arrayref
returned by _testsets().

=item $workflows = $wf->_workflows()

=item $wf->_workflows( \@workflows )

Get/Set the list of workflows, if you override add_item() and never caller
SUPER::add_item() then you will need to manually add Workflows to the arrayref
returned by _workflows().

=item run_tests()

In a normal Fennec run this will only be called on the root Workflow object.
Overriding this in your subclass will have NO EFFECT.

=item $wf->add_items( @items )

Bulk form of add_item().

=back

=head1 OTHER DOCUMENTATION

=over 4

=item L<Fennec::Workflow> Documentation for the root workflow object,
documentes inherited methods.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
