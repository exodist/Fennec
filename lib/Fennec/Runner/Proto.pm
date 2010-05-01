package Fennec::Runner::Proto;
use strict;
use warnings;

use Parallel::Runner;
use Carp;
use Digest::MD5 qw/md5_hex/;
use Cwd;
use Fennec::Util::PackageFinder;

use Fennec::Util::Alias qw/
    Fennec::FileLoader
    Fennec::Config
    Fennec::Util::Accessors
/;

use List::Util qw/shuffle/;
use Time::HiRes qw/time/;

Accessors qw/in/;

our @PROPERTIES = qw/
    ignore files collector handlers cull_delay threader parallel_files
    parallel_tests seed random filetypes default_asserts default_workflows
    search root_workflow_class
/;

sub new {
    my $class = shift;
    return bless({ in => {@_} }, $class );
}

sub rebless {
    my $self = shift;
    my ( $new_class ) = @_;
    return bless( $self->data, $new_class );
}

sub pids {
    my $self = shift;
    return (
        parent_pid => $$,
        pid        => $$,
    );
}

sub _or_config {
    my $self = shift;
    my ( $name, $default ) = @_;
    my %config = Config->fetch;

    return $ENV{ 'FENNEC_' . uc( $name )}
        || $config{ overrides }->{ $name }
        || $self->in->{ $name }
        || $config{ defaults }->{ $name }
        || $default;
}

for my $property ( @PROPERTIES, 'data' ) {
    my $sub = sub {
        my $self = shift;
        my ( $data_only ) = @_;
        my $get_from = "_$property";

        $self->{ $property } = $self->$get_from
            unless exists $self->{ $property };

        return $self->{ $property } if $data_only;
        return defined $self->{ $property }
            ? ($property => $self->{ $property })
            : ();
    };
    no strict 'refs';
    *$property = $sub;
}

sub _data {
    my $self = shift;
    return { map {( $self->$_ )} (@PROPERTIES, 'pids') };
}

sub _ignore {
    my $self = shift;
    return $self->in->{ ignore } || undef;
}

sub _files {
    my $self = shift;

    my $include = $ENV{ FENNEC_FILE }
        ? [ cwd() . '/' . $ENV{ FENNEC_FILE }]
        : $self->in->{ files };

    my $types = $self->filetypes( 1 );
    my @files = FileLoader->find_types( $types, $include );
    my $ignore = $self->ignore( 1 );

    @files = grep {
        my $file = $_;
        !grep { $file =~ $_ } @$ignore
    } @files if $ignore and @$ignore;

    die ( "No Fennec files found\n" )
        unless @files;

    @files = shuffle @files if $self->random(1);
    return \@files;
}

sub _collector {
    my $self = shift;
    my %config = Config->fetch;

    my $collector_class = $self->_or_config( 'collector', 'Files' );

    $collector_class = load_package( $collector_class, 'Fennec::Collector' );
    return $collector_class->new( @{ $self->handlers( 1 )});
}

sub _root_workflow_class {
    my $self = shift;
    my $class = $self->_or_config( 'root_workflow_class', 'Fennec::Workflow' );
    return load_package( $class, 'Fennec::Workflow' );
}

sub _handlers {
    my $self = shift;
    my $handlers = $self->in->{ handlers } || [ 'TAP' ];
    load_package( $_, 'Fennec::Handler' ) for @$handlers;
    return $handlers;
}

sub _cull_delay {
    my $self = shift;
    my %config = Config->fetch;
    return $self->_or_config( 'cull_delay', 0.1 );
}

sub _threader {
    my $self = shift;

    my $runner = Parallel::Runner->new(
        $self->parallel_files(1)
    ) or die( "No threader\n" );
    $runner->iteration_delay( $self->cull_delay( 1 ));

    return $runner;
}

sub _parallel_files {
    my $self = shift;
    return $self->_or_config( 'parallel_files', 2 );
}

sub _parallel_tests {
    my $self = shift;
    return $self->_or_config( 'parallel_tests', 2 );
}

sub _seed {
    my $self = shift;
    return $self->in->{ seed };
}

sub _random {
    my $self = shift;
    defined $self->in->{ random }
        ? $self->in->{ random }
        : 1;
}

sub _filetypes {
    my $self = shift;
    my $types = $self->in->{ filetypes } || [qw/ Module /];
    load_package( $_, 'Fennec::FileType' ) for @$types;
    return $types;
}

sub _default_asserts {
    my $self = shift;
    my $asserts = $self->in->{ default_asserts } || [qw/ Core /];
    load_package( $_, 'Fennec::Assert' ) for @$asserts;
    return $asserts;
}

sub _default_workflows {
    my $self = shift;
    my $workflows = $self->in->{ default_workflows } || [qw/Spec Case Methods/];
    load_package( $_, 'Fennec::Workflow' ) for @$workflows;
    return $workflows;
}

sub _search {
    my $self = shift;
    return $ENV{ FENNEC_ITEM };
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
