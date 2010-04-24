package TEST::Fennec::FileLoader::Module;
use strict;
use warnings;
use Fennec;

tests load => sub {
    require_ok( 'Fennec::FileLoader::Module' );
};

1;
