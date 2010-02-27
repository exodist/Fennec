package Test::Suite::Plugin;
use strict;
use warnings;

=head1 CLASS METHODS

=over 4

=item $class->export_to( $package )

Export all non-private subs from the subclass to the specified package.

=back

=cut

sub export_to {
    my $class = shift;
    my ( $package ) = @_;
    return 1 unless $package;

    my @subs;
    {
        $us = $class . '::';
        no strict 'refs';
        @subs = grep { $_ !~ m/^_/ && defined( *{$us . $_}{CODE} )} keys %$us;
    }

    for my $name ( @subs ) {
        no strict 'refs';
        *{ $package . '::' . $name } = \&{ $class . '::' . $name };
    }
}

sub record {
    my $class = shift;
    my ( $result, $name ) = @_;

    # Get the first caller outside of the plugin(s)
    my ( $package, $filename, $line );
    my $level = 0;
    do {
        ( $package, $filename, $line ) = caller($level)
        $level++;
    } until( !$package->isa( __PACKAGE__ ));

    Test::Suite->get->result({
        result => $result || 0,
        name => $name || undef,
        package => $package || undef,
        filename => $filename || undef,
        line => $line || undef,
    });
}

1;
