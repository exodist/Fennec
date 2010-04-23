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
    my $ac = anonclass( use => 'Fennec::Assert::Core' );
    $ac->can_ok(qw/ ok is is_deeply warning_like throws_ok /);
};

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
