package Fennec::TestSet::SubSet;
use strict;
use warnings;

use base 'Fennec::TestSet';

use Try::Tiny;
use Fennec::Util::Accessors;
use B;

use Fennec::Util::Alias qw/
    Fennec::Runner
    Fennec::Workflow
    Fennec::Output::Result
    Fennec::TestSet
    Fennec::TestSet::SubSet::Setup
/;

use List::Util   qw/shuffle min max/;
use Time::HiRes qw/time/;

Accessors qw/setups teardowns tests/;

sub new {
    my $class = shift;
    return bless(
        {
            setups => [],
            teardowns => [],
            tests => [],
            created_in => $$,
            @_,
        },
        $class
    );
}

sub lines_for_filter {
    my $self = shift;
    my @sets = map {[ $_->lines_for_filter ]}
        @{$self->tests}, @{$self->setups}, @{$self->teardowns};

    my $start = min( map { $_->[0] } @sets );
    my @ends = map { $_->[1] } @sets;
    my $end = (grep { !$_ } @ends) ? undef : max( @ends );
    return ( $start, $end );
}

sub start_line { my $list = [shift->lines_for_filter]; $list->[0] }
sub end_line { my $list = [shift->lines_for_filter]; $list->[1] }

sub run {
    my $self = shift;
    return Result->skiparallel_testset( $self, $self->skip )
        if $self->skip;

    $self->run_setups || return;
    my $ok = eval { $self->run_tests; 1 };
    my $msg = $@;
    $self->run_teardowns;
    return $ok || die ( $@ );
}

sub add_testset {
    my $self = shift;
    my ( $name, $sub ) = @_;
    my $line = B::svref_2object( $sub )->START->line;
    my $ts = TestSet->new( $name, method => $sub, line => $line );
    $ts->workflow( $self->workflow );
    push @{ $self->{ tests }} => $ts;
}

sub add_setup {
    my $self = shift;
    my $setup = Setup->new( @_ );
    push @{ $self->{ setups }} => $setup;

}

sub add_teardown {
    my $self = shift;
    my $setup = Setup->new( @_ );
    push @{ $self->{ teardowns }} => $setup;
}

sub run_setups {
    my $self = shift;
    return unless my $setups = $self->setups;
    for my $setup ( @$setups ) {
        return unless $setup->run_on( $self->testfile )
    }
    return 1;
}

sub run_tests {
    my $self = shift;
    return unless $self->tests;
    try {
        my @sets = @{ $self->tests };
        if ( Runner->search ) {
            @sets = $self->workflow->search_filter( Runner->search, \@sets );
        }

        @sets = shuffle @sets if $self->testfile->fennec_meta->random;
        @sets = sort { $a->name cmp $b->name } @sets
            if $self->testfile->fennec_meta->sort;

        my $start = time;
        for my $set ( @sets ) {
            $set->run()
        }
        my $end = time;
        Result->pass_testset( $self, [($end - $start)]) unless $self->no_result;
    }
    catch {
        return Result->skip_testset( $self, $1 )
            if ( m/SKIP:\s+(.*)/ );
        Result->fail_testset( $self, $_ );
    };
}

sub run_teardowns {
    my $self = shift;
    return unless my $teardowns = $self->teardowns;
    $_->run_on( $self->testfile ) for reverse @$teardowns;
}

sub observed {
    my $self = shift;
    my ( $val ) = @_;
    return $self->SUPER::observed unless $val;

    $self->SUPER::observed( $val );
    $_->observed( $val ) for @{ $self->tests };
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
F
