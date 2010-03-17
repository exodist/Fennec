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

Accessors qw/ group threader todo skip file /;

sub new {
    my $class = shift;
    my %proto = @_;
    my ( $todo, $skip, $group, $file ) = @proto{qw/ todo skip group file /};

    my $self = bless(
        {
            group       => $group,
            file        => $file,
            threader    => Threader->new( $proto{ p_tests }),
            skip        => $skip || undef,
            todo        => $todo || undef,
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
