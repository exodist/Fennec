#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Object::Quick qw/obj method/;

my @output;

my $CLASS = 'Fennec::Output::TAP';
use_ok( $CLASS );
ok( my $one = $CLASS->new( output => sub { push @output => @_ }), "Created" );
isa_ok( $one, $CLASS );

is( $one->count, 1, "Start counter" );
is( $one->count, 2, "More counter" );
is( $one->count, 3, "Yet more counter" );
ok( $one->finish, "Finished" );
is( shift( @output ), '1..3', "Plan" );
delete $one->{ count };

$one->diag( 'a', 'b', 'c' ), "diag";
is_deeply(
    \@output,
    [ '# a', '# b', '# c' ],
    "Diag output"
);

@output = ();
$one->result( obj(
    result => 1,
    name => 'test a',
    diag => undef,
    line => 1,
    file => 'fake',
    skip => undef,
    todo => undef,
));
is_deeply(
    \@output,
    [ 'ok 1 - test a' ],
    "ok result, no diag"
);

@output = ();
$one->result( obj(
    result => 0,
    name => 'test b',
    diag => [ 'help message' ],
    line => 1,
    file => 'fake',
    case => obj( name => 'case a' ),
    set => obj( name => 'set a' ),
    todo => undef,
    skip => undef,
));
is_deeply(
    \@output,
    [
        'not ok 2 - test b',
        "# Test failure at fake line 1",
        "#     case: case a",
        "#     set: set a",
        "# help message"
    ],
    "not ok result, with diag"
);

@output = ();
$one->result( obj(
    result => 0,
    name => 'test c',
    diag => [ 'help message' ],
    line => 1,
    file => 'fake',
    case => obj( name => 'case a' ),
    set => obj( name => 'set a' ),
    todo => "XXX",
    skip => undef,
));
is_deeply(
    \@output,
    [
        'not ok 3 - test c # TODO XXX',
        "# help message"
    ],
    "not ok result, with todo"
);

@output = ();
$one->result( obj(
    result => 0,
    name => 'test d',
    diag => [ 'help message' ],
    line => 1,
    file => 'fake',
    case => obj( name => 'case a' ),
    set => obj( name => 'set a' ),
    todo => undef,
    skip => "XXX",
));
is_deeply(
    \@output,
    [
        'ok 4 - test d # SKIP XXX',
        "# help message"
    ],
    "not ok result, with skip"
);


done_testing();

__END__

sub result {
    my $self = shift;
    my ( $result ) = @_;
    return unless $result;
    my $out = ($result->result ? 'ok ' : 'not ok ' ) . $self->count . " -";
    $out .= " " . $result->name if $result->name;
    if ( my $todo = $result->todo ) {
        $out .= " # TODO $todo";
    }
    elsif ( my $skip = $result->skip ) {
        $out .= " # SKIP $skip";
    }
    elsif ( !$result->result ) {
        $self->diag( "Test failure at " $result->file ." line " . $result->line );
    }
    $self->output( $out );
    my $diag = $result->diag;
    return unless $diag;
    $self->diag( $_ ) for @$diag
}

sub output {
    my $self = shift;
    $self->{ output }->( @_ );
}

1;
