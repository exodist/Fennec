package Fennec::TestFile::Meta;
use strict;
use warnings;

use Fennec::Util::Accessors;
use Try::Tiny;
use Carp;

use Fennec::Util::Alias qw/
    Fennec::Runner
/;

use Scalar::Util qw/blessed/;

our %MAP;

Accessors qw/ workflow threader todo skip file sort /;

sub set {
    my $class = shift;
    my ( $item, $meta ) = @_;
    $MAP{ $item } = $meta;
}

sub get {
    my $class = shift;
    my ( $item ) = @_;
    return $MAP{ $item };
}

sub new {
    my $class = shift;
    my %proto = @_;
    my ( $todo, $skip, $workflow, $file, $random, $sort ) = @proto{qw/ todo skip workflow file random sort /};

    my $self = bless(
        {
            workflow    => $workflow,
            file        => $file,
            threader    => Parallel::Runner->new(
                $proto{ no_fork } ? 1 : Runner->p_tests
            ),
            skip        => $skip || undef,
            todo        => $todo || undef,
            defined( $random ) || $sort
                ? (
                    random => $random || 0,
                    sort => $sort || undef,
                )
                : (),
        },
        $class
    );
    my $init = $class->can( 'init' ) || $class->can( 'initialize' );
    $self->$init( @_ ) if $init;
    return $self;
}

sub random {
    my $self = shift;
    ( $self->{ random }) = @_ if @_;
    return defined $self->{ random }
        ? $self->{ random }
        : Runner->random;
}

sub name { shift->file->filename }

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
