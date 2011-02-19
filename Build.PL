#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Fennec',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Carp'              => 0,
        'Exporter::Declare' => 0,
        'Mock::Quick'     => '1.000',
        'Parallel::Runner'  => '0.010',
        'Scalar::Util'      => 0,
        'List::Util'        => 0,
        'TAP::Parser'       => 0,
        'Test::Exception'   => '0.29',
        'Test::Simple'      => '0.88',
        'Test::Warn'        => 0,
    },
    build_requires => {
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Fennec',
            bugtracker  => 'http://github.com/exodist/Fennec/issues',
            homepage    => 'http://open-exodus.net/projects/Fennec'
        },
    }
);

$build->create_build_script;
