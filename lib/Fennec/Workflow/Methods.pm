package Fennec::Workflow::Methods;
use strict;
use warnings;

use Fennec::Util::Accessors;

use Fennec::Util::Alias qw/
    Fennec::Runner
    Fennec::TestSet::SubSet
    Fennec::Workflow
    Fennec::Util
/;

use Scalar::Util qw/blessed/;
use Fennec::Workflow qw/:subclass/;
use Carp;

Accessors qw/subset/;

build_hook {
    my ( $root_workflow ) = @_;
    $root_workflow->add_item( __PACKAGE__->new )
};

sub new {
    my $class = shift;
    return bless({ method => sub {1}, children => [] }, $class );
}

sub add_item { croak 'Children cannot be added to the Methods workflow' }

sub testsets {
    my $self = shift;

    unless( $self->subset ) {
        my $testfile = $self->testfile;
        my $tclass = blessed( $testfile );
        confess( "$testfile is not a blessed Fennec::TestFile" )
            unless $tclass;

        my @tests = Fennec::Util->package_sub_map( $tclass, qr/^test_/i );
        return unless @tests;

        my $subset = SubSet->new(
            name => 'Test Methods',
            workflow  => $self,
            file => $self->file,
        );
        $subset->add_setup( @$_ )
            for sort { $a->[0] cmp $b->[0] }
                Fennec::Util->package_sub_map( $tclass, qr/^setup/i );

        $subset->add_testset( @$_ ) for @tests;

        $subset->add_teardown( @$_ )
            for sort { $a->[0] cmp $b->[0] }
                Fennec::Util->package_sub_map( $tclass, qr/^teardown/i );

        $self->subset( $subset );
    }

    return $self->subset;
}

sub lines {
    my $self = shift;
    return 0 unless wantarray;
    my $subset = $self->testsets;
    return $subset->lines;
}

sub build_children {}

1;

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
