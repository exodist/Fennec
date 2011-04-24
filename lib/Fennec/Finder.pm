package Fennec::Finder;
use strict;
use warnings;

use base 'Fennec::Runner';
use File::Find qw/find/;

sub import {
    my $self = shift->new;
    $self->find_files( @_ );
    $self->inject_run( scalar caller )
}

sub find_files {
    my $self = shift;
    my @paths = @_;

    unless( @paths ) {
        @paths = -d './t' ? ( './t' ) : ( './' );
    }

    find(
        {
            wanted => sub {
                my $file = $File::Find::name;
                return unless $self->validate_file( $file );
                $self->load_file( $file );
            },
            no_chdir => 1,
        },
        @paths
    );
}

sub validate_file {
    my $self = shift;
    my ($file) = @_;
    return unless $file =~ m{\.pm$};
    return 1;
}

1;

__END__

=pod

=head1 NAME

Fennec::Finder - Create one .t file to find all .pm test files.

=head1 DESCRIPTION

Originally Fennec made use of a runner loaded in t/Fennec.t that sought out
test files (modules) to run. This modules provides similar, but greatly
simplified functionality.

=head1 SYNOPSIS

Fennec.t:

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Fennec::Finder;

    run();

This will find all .pm files under t/ and load them. Any that contain Fennec
tests will register themselves to be run once run() is called.

B<Warning, if you have .pm files that are not tests they will also be loaded,
if any of these have interactions with the packages you are testing you must
account for them.>

=head1 CUSTOMISATIONS

=head2 SEARCH PATHS

When you C<use Fennec::Finder;> the './t/' directory will be searched if it
exists, otherwise the './' directory will be used. You may optionally provide
alternate paths at use time: C<use Fennec::Finder './Fennec', './SomeDir';>

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Fennec::Finder './Fennec', './SomeDir';

    run();

=head2 FILE VALIDATION

If you wish to customize which files are loaded you may subclass
L<Fennec::Finder> and override the C<validate_file( $file )> method. This method takes
the filename to verify as an argument. Return true if the file should be
loaded, false if it should not. Currently the only check is that the filename
ends with a C<.pm>.

=head2 FILE LOADING

If you wish to customize which files are loaded you may subclass
L<Fennec::Finder> and override the C<load_file( $file )> method. Currently this
method simply calles C<require $file.> with some extra debugging code wrapped
around it.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

=cut
