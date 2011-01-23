package Test::Workflow::Block;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use Carp qw/croak/;
use B ();
use Scalar::Util qw/blessed/;

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

sub clone_with {
    my $self = shift;
    my %params = @_;
    bless({ %$self, %params}, blessed($self));
}

sub run {
    my $self = shift;
    my ( $instance, $layer ) = @_;
    my $success = eval { $self->code->( @_ ); 1 };

    return if $success && !$self->verbose;

    my $error = $@ || "Error masked!";
    chomp( $error );

    my $ok = $instance->TEST_WORKFLOW->ok
          || Test::More->can( 'ok' )
          || Test::Simple->can( 'ok' )
          || sub {
              warn( "Block failed: " . join( ', ', map { "'$_'" } @_ ));
          };

    my $diag = $instance->TEST_WORKFLOW->diag
          || Test::More->can( 'diag' )
          || Test::Simple->can( 'diag' )
          || sub {
              die( "Additional info: " . join( ', ', map { "'$_'" } @_ ));
          };

    $ok->(
        $success || 0,
        $self->name,
    );

    $diag->(
        "  ================================"
        . "\n  Error: " . $error
        . "\n  Package: " . $self->package
        . "\n  Block: '" . $self->name . "' on " . $self->diag
        . "\n\n"
    ) unless $success;
}

1;

__END__

=head1 NAME

=head1 DESCRIPTION

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
