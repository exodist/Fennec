package Fennec::Runner::Proto;
use strict;
use warnings;

use Parallel::Runner;
use Carp;
use Digest::MD5 qw/md5_hex/;
use Cwd;

use Fennec::Util::Alias qw/
    Fennec::FileLoader
    Fennec::Config
    Fennec::Util::Accessors
/;

use List::Util qw/shuffle/;
use Time::HiRes qw/time/;

Accessors qw/in/;

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

    return $config{ overrides }->{ $name }
        || $self->in->{ $name }
        || $config{ defaults }->{ $name }
        || $default;
}

for my $accessor (
qw/
    ignore files collector handlers cull_delay threader parallel_files
    parallel_tests seed random data filetypes default_asserts default_workflows
    search
/
) {
    my $sub = sub {
        my $self = shift;
        my ( $data_only ) = @_;
        my $get_from = "_$accessor";

        $self->{ $accessor } = $self->$get_from
            unless exists $self->{ $accessor };

        return $self->{ $accessor } if $data_only;
        return defined $self->{ $accessor }
            ? ($accessor => $self->{ $accessor })
            : ();
    };
    no strict 'refs';
    *$accessor = $sub;
}

sub _data {
    my $self = shift;
    return { map {( $self->$_ )} qw/
        collector
        cull_delay
        default_asserts
        default_workflows
        files
        filetypes
        handlers
        ignore
        parallel_files
        parallel_tests
        pids
        random
        search
        seed
        threader
    / };
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

    $collector_class = 'Fennec::Collector::' . $collector_class;
    eval "require $collector_class; 1" || die( $@ );
    return $collector_class->new( @{ $self->handlers( 1 )});
}

sub _handlers {
    my $self = shift;
    my $handlers = $self->in->{ handlers } || [ 'TAP' ];
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
    return $self->in->{ filetypes } || [qw/ Module /];
}

sub _default_asserts {
    my $self = shift;
    return $self->in->{ default_asserts } || [qw/ Core /];
}

sub _default_workflows {
    my $self = shift;
    return $self->in->{ default_workflows } || [qw/Spec Case Methods/],
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
