package Fennec::Output::TestBuilder;
use strict;
use warnings;
use Test::Builder;
use Fennec::TestBuilderImposter;

use base 'Fennec::Output';

sub tb {
    my $self = shift;
    ($self->{ tb }) = @_ if @_;
    return $self->{ tb };
}

sub init {
    my $self = shift;
    $self->tb( Test::Builder->new );
}

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;
    $self->tb->real_ok($result->result || 0, $result->name);
    $self->tb->real_diag( $_ ) for @{ $result->diag || []};
}

sub diag {
    my $self = shift;
    $self->tb->real_diag( @_ );
}

sub finish {
    my $self = shift;
    $self->tb->done_testing();
}

1;

__END__

