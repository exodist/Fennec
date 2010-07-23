package Fennec::Runner::Config;
use strict;
use warnings;

use Parallel::Runner;
use Cwd;
use Fennec::Util::PackageFinder;

use Fennec::Util::Alias qw/
    Fennec::FileLoader
/;

use List::Util qw/shuffle/;
use Fennec::Runner qw/add_config/;

add_config pid            => sub { $$ };
add_config parent_pid     => sub { $$ };
add_config cull_delay     => 0.1;
add_config parallel_files => 2;
add_config parallel_tests => 2;
add_config random         => 1;
add_config ignore         => undef;
add_config load           => sub {[]};

add_config files => (
    env_override => 'FENNEC_FILE',
    depends => [ qw/ filetypes ignore random /],
    modify => sub {
        my ($value, $data) = @_;

        if ( $value ) {
            # Single value is FENNEC_FILE, multiple is runner
            $value = [ cwd() . '/' . $value ]
                unless ref $value;
        }

        my $types = $data->{filetypes};
        my @files = FileLoader->find_types( $types, $value );
        my $ignore = $data->{ ignore };

        @files = grep {
            my $file = $_;
            !grep { $file =~ $_ } @$ignore
        } @files if $ignore and @$ignore;

        die ( "No Fennec files found\n" )
            unless @files;

        @files = shuffle @files if $data->{ random };
        return \@files;
    },
);

add_config collector => (
    depends => [ qw/ handlers /],
    default => 'Files',
    modify  => sub {
        my ($value, $data) = @_;
        my $class = load_package( $value, 'Fennec::Collector' );
        return $class->new( @{ $data->{ handlers }});
    },
);

add_config root_workflow_class => (
    default => 'Fennec::Workflow',
    modify  => sub { load_package( $_[0], 'Fennec::Workflow' )},
);


add_config handlers => (
    default => [ 'TAP' ],
    modify  => sub {
        my ($value) = @_;
        return [ map {
            load_package( $_, 'Fennec::Handler' )
        } @$value ];
    },
);

add_config threader => (
    depends => [ qw/ parallel_files cull_delay /],
    default => sub {
        my ($data) = @_;
        my $runner = Parallel::Runner->new(
            $data->{ parallel_files }
        ) or die( "No threader\n" );
        $runner->iteration_delay( $data->{ cull_delay });
        return $runner;
    },
);

add_config filetypes => (
    default => [ 'Module' ],
    modify  => sub {
        my ( $value, $data ) = @_;
        return [ map {
            load_package( $_, 'Fennec::FileType' )
        } @$value ];
    },
);

add_config default_asserts => (
    default => [ 'Core' ],
    modify  => sub {
        my ( $value, $data ) = @_;
        return [ map {
            load_package( $_, 'Fennec::Assert' )
        } @$value ];
    },
);

add_config default_workflows => (
    default => [qw/Spec Case Methods/],
    modify  => sub {
        my ( $value, $data ) = @_;
        return [ map {
            load_package( $_, 'Fennec::Workflow' )
        } @$value ];
    },
);

add_config search => (
    env_override => 'FENNEC_ITEM',
);

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
