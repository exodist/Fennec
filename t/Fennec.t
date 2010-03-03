#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;
use Test::Builder::Tester;
use Fennec::TestHelper;

my $CLASS = 'Fennec';
require Fennec;

{
    package My::LoadIt;
    use strict;
    use warnings;
    BEGIN {
        $INC{ 'My/LoadIt.pm' } = __FILE__;
        our @EXPORT = qw/return_a/;
        our @EXPORT_OK = qw/return_b/;
    }
    use base 'Exporter';

    sub return_a { 'a' };
    sub return_b { 'b' };

    package My::LoadIt2;
    use strict;
    use warnings;
    BEGIN{ $INC{ 'My/LoadIt2.pm' } = __FILE__ }

    sub import {
        my ($caller) = caller;
        no strict 'refs';
        *{$caller . '::return_c'} = sub {'c'};
    }

    package My::TestA;
    use strict;
    use warnings;
    use Fennec testing => 'My::LoadIt';

    package My::TestB;
    use strict;
    use warnings;
    use Fennec testing => 'My::LoadIt',
                    import_args => [ 'return_b' ];

    package My::TestC;
    use strict;
    use warnings;
    use Fennec testing => 'My::LoadIt2';
}

real_tests {
    throws_ok { package My::Test::Die; Fennec->import( testing => 'Fake::Package::Name' )}
              qr{Can't locate Fake/Package/Name\.pm},
              "Dies when testing invalid or broken package";

    isa_ok( 'My::TestA', 'Fennec::Test' );
    can_ok( 'My::TestA', qw/ok throws_ok is_deeply warning_is return_a test_set test_case/ );

    isa_ok( 'My::TestB', 'Fennec::Test' );
    can_ok( 'My::TestB', qw/ok throws_ok is_deeply warning_is return_b test_set test_case/ );

    isa_ok( 'My::TestC', 'Fennec::Test' );
    can_ok( 'My::TestC', qw/ok throws_ok is_deeply warning_is return_c test_set test_case/ );
};

done_testing;
