package Test::Workflow::Meta;
use strict;
use warnings;

use Test::Workflow::Layer;

use Fennec::Util qw/accessors/;

accessors qw/test_class build_complete root_layer test_run test_sort ok diag/;

sub new {
    my $class = shift;
    my ( $test_class ) = @_;
    return bless({
        test_class => $test_class,
        root_layer => Test::Workflow::Layer->new(),
    }, $class );
}

1;

__END__

=head1 NAME

=head1 DESCRIPTION

=head1 API STABILITY

Fennec versions below 1.000 were considered experimental, and the API was
subject to change. As of version 1.0 the API is considered stabalized. New
versions may add functionality, but not remove or significantly alter existing
functionality.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
