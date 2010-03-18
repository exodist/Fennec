package Fennec::Result;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Runner;

our @ITEM_OR_TEST_ACCESSORS = qw/ skip todo /;
our @ITEM_ACCESSORS = qw/ name file line /;
our @SIMPLE_ACCESSORS = qw/pass item diag benchmark/;
our @PROPERTIES = (
    @ITEM_ACCESSORS,
    @SIMPLE_ACCESSORS,
    @ITEM_OR_TEST_ACCESSORS,
    qw/ test /,
);
our $TODO;

Accessors @SIMPLE_ACCESSORS;

sub TODO {
    my $class = shift;
    ($TODO) = @_ if @_;
    return $TODO;
}

sub fail { !shift->pass }

sub new {
    my $class = shift;
    my ( $pass, $item, %proto ) = @_;
    return bless(
        {
            $TODO ? ( todo => $TODO ) : (),
            %proto,
            pass => $pass ? 1 : 0,
            item => $item || undef,
            test => Runner->current || undef,
        },
        $class
    );
}

sub fail_item {
    my $class = shift;
    my ( $item, @diag ) = @_;
    Runner->handler->result( $class->new( 0, $item, diag => \@diag ));
}

sub skip_item {
    my $class = shift;
    my ( $item, $reason, @diag ) = @_;
    $reason ||= $item->skip if $item->can( 'skip' );
    $reason ||= "no reason";
    Runner->handler->result( $class->new( 0, $item, skip => $reason, diag => \@diag ));
}

sub pass_item {
    my $class = shift;
    my ( $item, @diag ) = @_;
    Runner->handler->result( $class->new( 1, $item, diag => \@diag ));
}

for my $item_accessor ( @ITEM_ACCESSORS ) {
    no strict 'refs';
    *$item_accessor = sub {
        my $self = shift;
        return $self->{ $item_accessor }
            if $self->{ $item_accessor };

        return undef unless $self->item
                        and $self->item->can( $item_accessor );

        return $self->item->$item_accessor;
    };
}

for my $any_accessor ( @ITEM_OR_TEST_ACCESSORS ) {
    no strict 'refs';
    *$any_accessor = sub {
        my $self = shift;
        return $self->{ $any_accessor }
            if $self->{ $any_accessor };

        return $self->item->$any_accessor
            if $self->item && $self->item->can( $any_accessor );

        return $self->test->$any_accessor
            if $self->test && $self->test->can( $any_accessor );
    };
}

sub test {
    my $self = shift;
    if ( my $item = $self->item ) {
        return $item if $item->isa( 'Fennec::Test' );
        my $test = $item->test if $item->can( 'test' );
        return $test if $test;
    }
    return $self->{ test };
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
