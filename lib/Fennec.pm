package Fennec;
use strict;
use warnings;

use Exporter::Declare;
use Fennec::Util qw/inject_sub/;

sub defaults {(
    utils => [qw/Test::More Test::Warn Test::Exception/],
    handler => 'Fennec::Handler::TAP',
    parallel => 0,
)}

sub init {}

sub after_import {
    my $class = shift;
    my ( $importer, $specs ) = @_;

    if ( $0 eq (caller(1))[1] ) {
        $ENV{PERL5LIB} = join( ':', @INC );
        exec "$^X -MFennec::Runner -e 'Fennec::Runner::run_file(\"$0\")'";
    }

    require Fennec::Meta::TestClass;
    my $meta = Fennec::Meta::TestClass->new( fennec => $class, class => $importer );
    inject_sub( $importer, 'FENNEC', sub { $meta });

    for my $util ( @{ $meta->utils }) {
        eval "package $importer; require $util; $util\->import(); 1" || die $@;
    }

    $class->init( $importer, $specs );
}

default_export parallel => sub {
    caller->FENNEC->parallel( @_ );
};

sub tests {
    my $caller = caller;
}

default_export tests => \&tests;
default_export it => \&tests;

default_export cases => sub {
    my $caller = caller;
};

default_export case => sub {
    my $caller = caller;
};

default_export describe => sub {
    my $caller = caller;
};

default_export before_all => sub {
    my $caller = caller;
};

default_export after_all => sub {

};

default_export before_each => sub {

};

default_export after_each => sub {

};

1;
