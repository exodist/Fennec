package Fennec::Listener::TB;
use strict;
use warnings;

use Fennec::Listener::TB::Collector;
use Fennec::Listener::TB::Handle;
use Test::Builder();

use base 'Fennec::Listener';

use Fennec::Util qw/accessors get_test_call/;
use Test::Builder;

accessors qw/collector tbout tberr/;

sub ok         { shift; Test::Builder->new->ok(@_) }
sub diag       { shift; Test::Builder->new->diag(@_) }
sub skip       { shift; Test::Builder->new->skip(@_) }
sub todo_start { shift; Test::Builder->new->todo_start(@_) }
sub todo_end   { shift; Test::Builder->new->todo_end }

sub new {
    my $class = shift;

    my $tbout = tie( *TBOUT, 'Fennec::Listener::TB::Handle', 'STDOUT' );
    my $tberr = tie( *TBERR, 'Fennec::Listener::TB::Handle', 'STDERR' );

    my $self = bless(
        {
            collector => Fennec::Listener::TB::Collector->new(),
            tbout     => $tbout,
            tberr     => $tberr,
        },
        $class
    );

    my $tb = Test::Builder->new();
    $tb->no_ending(1);

    my $old = select(TBOUT);
    $| = 1;
    select(TBERR);
    $| = 1;
    select($old);

    $tb->output( \*TBOUT );
    $tb->todo_output( \*TBOUT );
    $tb->failure_output( \*TBERR );

    $self->setup_child( $self->collector );

    return $self;
}

sub setup_child {
    my $self = shift;
    my ($handle) = @_;

    $self->tbout->out($handle);
    $self->tberr->out($handle);
}

sub process {
    my $self = shift;
    $self->collector->process(@_);
}

sub terminate {
    my $self = shift;
    $self->collector->terminate(@_);
}

1;

__END__

=head1 NAME

Fennec::Listener::TB - Listener used with Test::Builder

=head1 DESCRIPTION

This configured the Test::Builder singleton so that it will work with multiple
processes by sending all results and diag to a central process.

=head1 API STABILITY

Fennec versions below 1.000 were considered experimental, and the API was
subject to change. As of version 1.0 the API is considered stabalized. New
versions may add functionality, but not remove or significantly alter existing
functionality.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
