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
        'Benchmark'         => 0,
        'Cwd'               => 0,
        'IO'                => 1.2301,
        'List::Util'        => 0,
        'List::MoreUtils'   => 0,
        'Module::Pluggable' => 3,
        'Scalar::Util'      => 0,
        'Test::Simple'      => 0.88,
        'Test::Warn'        => 0,
        'Time::HiRes'       => 0,
        'Try::Tiny'         => 0,
    },
    no_index => {
        package => [qw{
            Test::Builder
        }],
        namespace => [qw{
            Test::Builder
        }],
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Fennec',
            bugtracker  => 'http://github.com/exodist/Fennec/issues',
        },
    }
);

$build->create_build_script;
