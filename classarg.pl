use Fennec class => 'Foo::Bar';

ok( $INC{'Foo/Bar.pm'}, "Loaded 'Foo::Bar'" );
is( $CLASS,  'Foo::Bar', "We have \$CLASS" );
is( class(), 'Foo::Bar', "We have class()" );

tests method => sub {
    my $self = shift;
    is( $self->class(), 'Foo::Bar', "We have class() method" );
};

done_testing;
