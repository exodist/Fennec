#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Fennec',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    script_files => "script",
    requires => {
        # Core
        'Benchmark'         => 0,
        'Cwd'               => 0,
        'Data::Dumper'      => 0,
        'List::Util'        => 0,
        'Scalar::Util'      => 0,
        'Time::HiRes'       => 0,

        # External
        'List::MoreUtils'   => 0,
        'Try::Tiny'         => 0,

        # Made for Fennec
        'Parallel::Runner'  => 0.004,
        'Exporter::Declare' => 0.003,
    },
    no_index => {
        package   => [qw{ Test::Builder }],
        namespace => [qw{ Test::Builder }],
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Fennec',
            bugtracker  => 'http://github.com/exodist/Fennec/issues',
        },
    }
);

$build->create_build_script;
