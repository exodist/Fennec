package Test::Workflow::Meta;
use strict;
use warnings;

use Test::Workflow::Layer;
use Test::Builder;

use Fennec::Util qw/accessors/;

accessors qw/
    test_class build_complete root_layer test_run test_sort
    ok diag skip todo_start todo_end
/;

sub new {
    my $class = shift;
    my ( $test_class ) = @_;

    my $tb = "tb";
    $tb = "tb2" if eval { require Test::Builder2; 1 };

    my $self = bless({
        test_class => $test_class,
        root_layer => Test::Workflow::Layer->new(),
        ok         => Fennec::Util->can( "${tb}_ok"         ),
        diag       => Fennec::Util->can( "${tb}_diag"       ),
        skip       => Fennec::Util->can( "${tb}_skip"       ),
        todo_start => Fennec::Util->can( "${tb}_todo_start" ),
        todo_end   => Fennec::Util->can( "${tb}_todo_end"   ),
    }, $class );

    return $self;
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
