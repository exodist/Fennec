package TEST::Fennec::Assert::Core;
use strict;
use warnings;
use Fennec;

tests 'Bad core module' => sub {
    local @Fennec::Assert::Core::CORE_LIST = qw/FAKEMODULE/;
    throws_ok { Fennec::Assert::Core->export_to( 'main', 'bubba_' )}
        qr{Can't locate Fennec/Assert/Core/FAKEMODULE\.pm in \@INC},
        "Can't load";
};

tests 'direct use' => sub {
    eval '
        package TEST::Fennec::Assert::Core::Import;
        use strict;
        use warnings;
        use Fennec::Assert::Core;
        1;
    ' || die( $@ );
    can_ok(
        'TEST::Fennec::Assert::Core::Import',
        qw/ok is is_deeply warning_like throws_ok/
    );
};

1;
