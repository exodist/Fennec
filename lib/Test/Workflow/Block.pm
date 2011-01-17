package Test::Workflow::Block;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use Carp qw/croak/;

our @CARP_NOT = qw/
    Test::Workflow
    Test::Workflow::Meta
    Test::Workflow::Block
    Test::Workflow::Layer
/;

accessors qw/ name start_line end_line code /;

sub new {
    my $class = shift;
    my ( $caller, $name, $code ) = @_;

    croak "You must provide a name" unless $name and !ref $name;
    croak "You must provide a codeblock" unless $code && ref $code eq 'CODE';

    return bless({
        name => $name,
        code => $code,
        end_line => $caller->[3],
        start_line => B::svref_2object( $code )->START->line,
    }, $class);
}

1;
