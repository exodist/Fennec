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

accessors qw/ name start_line end_line code verbose package diag/;

sub new {
    my $class = shift;
    my ( $caller, $name, $code, $verbose ) = @_;

    croak "You must provide a caller" unless $caller && @$caller;
    croak "You must provide a name" unless $name and !ref $name;
    croak "You must provide a codeblock" unless $code && ref $code eq 'CODE';

    my $start_line = B::svref_2object( $code )->START->line;
    my $end_line = $caller->[2];
    $start_line-- unless $start_line == $end_line;

    return bless({
        name       => $name,
        code       => $code,
        package    => $caller->[0],
        start_line => $start_line,
        end_line   => $end_line,
        verbose    => $verbose ? 1 : 0,
        diag       => ($start_line == $end_line) ? "line $start_line"
                                                 : "lines $start_line -> $end_line",
    }, $class);
}

sub run {
    my $self = shift;
    my $success = eval { $self->code->( @_ ); 1 };

    return if $success && !$self->verbose;
    my $error = $@ || "Error masked!";
    chomp( $error );

    Fennec::Runner->ok(
        $success || 0,
        $self->name,
        "  ================================"
        . "\n  Error: " . $error
        . "\n  Package: " . $self->package
        . "\n  Block: '" . $self->name . "' on " . $self->diag
        . "\n\n"
    );
}

1;
