package TEST::Fennec::Util::PackageFinder;
use strict;
use warnings;

use Fennec;
use File::Temp qw/ tempfile /;
our $CLASS = 'Fennec::Util::PackageFinder';

require_ok $CLASS;

tests use => sub {
    my $ac = anonclass( use => $CLASS );
    my $one = $ac->new;
    $one->can_ok( 'load_package' );
};

tests load_package => sub {
    local *load_package = $CLASS->can( 'load_package' );
    throws_ok { load_package( '_XXXX' )}
        qr/Could not find _XXXX as _XXXX/,
        "Just package";

    throws_ok { load_package( '_XXXX::YYYY' )}
        qr/Could not find _XXXX::YYYY as _XXXX::YYYY/,
        "Just package 2 parts";

    throws_ok { load_package( '_XXXX', 'AAAA' )}
        qr/Could not find _XXXX as _XXXX or AAAA::_XXXX/,
        "namespace 1 part";

    throws_ok { load_package( '_XXXX::YYYY', 'AAAA' )}
        qr/Could not find _XXXX::YYYY as AAAA::_XXXX::YYYY or _XXXX::YYYY/,
        "namespace 2 parts";

    is(
        load_package( 'Util::PackageFinder', 'Fennec' ),
        'Fennec::Util::PackageFinder',
        "Found package"
    );

    is(
        load_package( 'Fennec::Util::PackageFinder' ),
        'Fennec::Util::PackageFinder',
        "Found package"
    );

    my $package = 'AAAAAAAAA';
    $package++ while ( -e "$package.pm" );
    open( my $fh, '>', "$package.pm" ) || die( $! );
    print $fh "package $package;\n { \n; 1\n";
    close( $fh );
    {
        local @INC = ('.', @INC);
        throws_ok { load_package( $package ) }
            qr/Missing right curly or square bracket at $package\.pm line 3/,
            "Forwards message when loading fails but file found";
    }
    eval { unlink "$package.pm" } || warn "Failed to unlink $package.pm";
};

1;
