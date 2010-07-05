package Test::Action::DoubleDescribe;
use strict;
use warnings;
use Carp::Always;
use Fennec;


tests load {
   require_ok( 'Fennec' );
   use_ok( 'Fennec' );
   can_ok( 'Fennec', qw{
      import
      new
   });
}


describe 'feature' {
   describe 'feature' {
   
      it 'will work' {
         ok(1, 'HUZZA!');
      }

   }
}

1;



