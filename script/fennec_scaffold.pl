#!/usr/bin/perl
use strict;
use warnings;

use File::Find;
use File::Path qw(make_path);

our %MODULES;

our $lib_dir = $ENV{FENNEC_LIB_DIR} || $ARGV[0] || './lib';

find(
    sub {
        my $name = $File::Find::name;
        return unless $name =~ m/\.pm$/;
        $MODULES{ $name } = [ $File::Find::dir, $_ ];
    },
    $lib_dir
);

for my $item ( values %MODULES ) {
    $item->[0] =~ s|^\Q$lib_dir\E|./t|;
    my $test = join( '/', @$item );
    next if -e $test;
    mktest( $item, $test );
}

sub mktest {
    my ( $item, $test ) = @_;
    my $package = file_to_package( $test );
    make_path( $item->[0] );
    open( my $FILE, '>', $test ) || die( "Error creating file '$test': $!" );
    print $FILE <<EOT;
package TEST\::$package;
use strict;
use warnings;
use Fennec;

tests load {
    require_ok( '$package' );
}

1;
EOT
    close( $FILE )
}

sub file_to_package {
    my ( $file ) = @_;
    my $out = $file;
    $out =~ s|^(.*/)?t/||g;
    $out =~ s|\.pm$||g;
    $out =~ s|/+|::|g;
    return $out;
}

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
