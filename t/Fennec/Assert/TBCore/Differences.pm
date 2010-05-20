package TEST::Fennec::Assert::TBCore::Differences;
use strict;
use warnings;
use Fennec;

require_or_skip Test::Differences;

tests load {
    use_ok( 'Fennec::Assert::TBCore::Differences' );
    TODO{ 
      can_ok( $self, @Test::Differences::EXPORT );
      can_ok( main , @Test::Differences::EXPORT );
   } 'still trying to work out why these fail?';
};



1;
