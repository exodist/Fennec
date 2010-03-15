package Fennec::Test;
use strict;
use warnings;

use base 'Fennec::Base';

use Fennec::Util::Accessors;
use Fennec::Test::Stack;
use Fennec::Util::Threader;
use Fennec::Runner;
use Try::Tiny;
use Carp;

use Scalar::Util qw/blessed/;

our $NEW;

Accessors qw/ stack threader todo skip file _init_args /;

sub init { return shift }

sub new_from_file {
    my $class = shift;
    my ( $file ) = @_;
    local $NEW;
    local Runner->{ current };
    $file->load;
    my $self = $class->_new;
    croak( "File $file->name did not create a new test object." )
        unless $self;
    $self->init(@{ $self->_init_args });
    $self->file( $file );
    return $self;
}

sub _new {
    my $class = shift;
    ( $NEW ) = @_ if @_;
    return $NEW;
}

sub new {
    my $class = shift;
    my %proto = @_;
    my ( $todo, $skip ) = @proto{qw/ todo skip /};

    my $self = bless(
        {
            stack       => Stack->new,
            threader    => Threader->new( $proto{ p_tests }),
            skip        => $skip || undef,
            todo        => $todo || undef
        },
        $class
    );
    $self->init( @_ );
    return $self;
}

sub random {
    my $self = shift;
    return defined $self->{ random }
        ? $self->{ random }
        : Runner->random;
}

sub run { shift->stack->run }
sub filename { shift->file->filename }
sub name { return blessed( $_[0] )}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
