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
        'Scalar::Util'      => 0,
        'TAP::Parser'       => 0,
        'Exporter::Declare' => 0,
    },
    build_requires => {
        'Test::Simple'    => 0.88,
        'Test::Exception' => 0.29,
        'Test::Warn'      => 0,
        'Object::Quick'   => 0,
    },
);

$build->create_build_script;
