package Fennec::TestFile;
use strict;
use warnings;

use Fennec::TestFile::Meta;

sub fennec_new {
    my $class = shift;
    if ( $class->can( 'new' )) {
        return $class->new();
    }
    else {
        my $new = bless( {}, $class );
        $new->init if $new->can( 'init' );
        return $new;
    }
}

sub fennec_meta {
    my $self = shift;
    Fennec::TestFile::Meta->get( $self );
}

sub stash {
    my $self = shift;
    $self->fennec_meta->stash( @_ );
}

1;

=head1 MANUAL

=over 2

=item L<Fennec::Manual::Quickstart>

The quick guide to using Fennec.

=item L<Fennec::Manual::User>

The extended guide to using Fennec.

=item L<Fennec::Manual::Developer>

The guide to developing and extending Fennec.

=item L<Fennec::Manual>

Documentation guide.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
