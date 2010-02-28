#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Suite',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'File::Find' => 0,
        'Test::Simple' => 0.88,
        'IO' => 1.2301,
        'File::Temp' => 0.20,
        'Scalar::Util' => 0,
        'Time::HiRes' => 0,
        'autodie' => 0,
        'Test::Warn' => 0,
        'Sub::Uplevel' => 0.20,
    },
    build_requires => {
        'Test::Exception::LessClever' => '0.001',
        'Test::Builder::Tester' => 0,
        'Object::Quick' => '0.012',
    },
);

$build->create_build_script;
