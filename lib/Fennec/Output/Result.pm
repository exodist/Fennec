package Fennec::Output::Result;
use strict;
use warnings;

use base 'Fennec::Output';

use Fennec::Util::Accessors;
use Fennec::Runner;
use Fennec::Workflow;
use Try::Tiny;

use Scalar::Util qw/blessed/;
use Fennec::Util::Alias qw/
    Fennec::Runner
/;

our @ANY_ACCESSORS = qw/ skip todo name file line/;
our @SIMPLE_ACCESSORS = qw/ pass benchmark /;
our @PROPERTIES = (
    @SIMPLE_ACCESSORS,
    @ANY_ACCESSORS,
    qw/ stderr stdout workflow_stack testfile /,
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
    my %proto = @_;
    my $pass = delete $proto{ pass };

    return bless(
        {
            $TODO ? ( todo => $TODO ) : (),
            %proto,
            pass => $pass ? 1 : 0,
            $proto{'benchmark'} ? () : (benchmark => Runner->benchmark() || undef),
        },
        $class
    );
}

for my $any_accessor ( @ANY_ACCESSORS ) {
    no strict 'refs';
    *$any_accessor = sub {
        my $self = shift;
        return $self->{ $any_accessor }
            if $self->{ $any_accessor };

        my @any = ( $self->testset, $self->workflow, $self->testfile );
        for my $item ( @any ) {
            next unless $item;
            next unless $item->can( $any_accessor );

            my $found = $item->$any_accessor;
            next unless $found;

            return $found;
        }
    };
}

for my $type ( qw/workflow testfile testset/ ) {
    my $fail = sub {
        my $class = shift;
        my ( $item, @stderr ) = @_;
        $class->new(
            pass => 0,
            $type => $item,
            $item->can( 'name' ) ? ( name => $item->name ) : (),
            stderr => \@stderr,
        )->write;
    };
    my $pass = sub {
        my $class = shift;
        my ( $item, $benchmark, @stderr ) = @_;
        $class->new(
            pass => 1,
            $type => $item,
            name => $item->name,
            benchmark => $benchmark,
            stderr => \@stderr,
        )->write;
    };
    my $skip = sub {
        my $class = shift;
        my ( $item, $reason, @stderr ) = @_;
        $reason ||= $item->skip || "no reason";
        $class->new(
            pass => 1,
            $type => $item,
            name => $item->name,
            skip => $reason,
            stderr => \@stderr,
        )->write;
    };
    no strict 'refs';
    *{ "fail_$type" } = $fail;
    *{ "pass_$type" } = $pass;
    *{ "skip_$type" } = $skip;
}

sub serialize {
    my $self = shift;
    my $data = { map {( $_ => ( $self->$_ || undef ))} @PROPERTIES };
    return {
        bless => ref( $self ),
        data => $data,
    };
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
