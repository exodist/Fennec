#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

eval {
    use lib 'lib';
    require 'lib/Fennec.pm';
};

my $build = Module::Build->new(
    module_name => 'Fennec',
    dist_version_from => 'lib/Fennec/Manual.pm',
    dist_version     => $Fennec::VERSION || 0.001,
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'File::Find'   => 0,
        'File::Temp'   => 0.20,
        'IO'           => 1.2301,
        'List::Util'   => 0,
        'Scalar::Util' => 0,
        'Sub::Uplevel' => 0.20,
        'Test::Simple' => 0.88,
        'Test::Warn'   => 0,
        'Time::HiRes'  => 0,
        'Try::Tiny'    => 0,
        'autodie'      => 0,
    },
    build_requires => {
        'Object::Quick'               => '0.012',
        'Test::Builder::Tester'       => 0,
        'Test::Exception::LessClever' => '0.001',
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
