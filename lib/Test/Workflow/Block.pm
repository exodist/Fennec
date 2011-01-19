package Test::Workflow::Block;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use Carp qw/croak/;
use B ();

our @CARP_NOT = qw/
    Test::Workflow
    Test::Workflow::Meta
    Test::Workflow::Block
    Test::Workflow::Layer
/;

accessors qw/ name start_line end_line code verbose /;

sub new {
    my $class = shift;
    my ( $caller, $name, $code, $verbose ) = @_;

    croak "You must provide a caller" unless $caller && @$caller;
    croak "You must provide a name" unless $name and !ref $name;
    croak "You must provide a codeblock" unless $code && ref $code eq 'CODE';

    return bless({
        name => $name,
        code => $code,
        end_line => $caller->[2],
        start_line => B::svref_2object( $code )->START->line,
        verbose => $verbose ? 1 : 0,
    }, $class);
}

sub run {
    my $self = shift;
    my $success = eval { $self->code->( @_ ); 1 };

    return if $success && !$self->verbose;
    my $error = $@ || "Error masked!";

    Fennec::Runner->ok(
        $success || 0,
        $self->name,
        $error,
        "Codeblock info: name: " . $self->name
        . ", Approx lines " . $self->start_line . "->" . $self->end_line . ".",
    );
}

1;
