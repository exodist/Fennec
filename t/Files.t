#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;

my $CLASS;
BEGIN {
    $CLASS = 'Fennec::Files';
    use_ok( $CLASS, 'add_to_wanted' );
}

can_ok( __PACKAGE__, 'add_to_wanted' );
can_ok( $CLASS, qw/bad_files list types/ );

my $wanted;
{
    no warnings 'once';
    $wanted = \%Fennec::Files::WANTED;
}

add_to_wanted( 'a', qr{good_file}, sub { die( "died" ) if $_[0] =~ m/die/; 1 });
ok( $wanted->{ a }, "a added" );
isa_ok( $wanted->{ a }->[0], 'Regexp' );
isa_ok( $wanted->{ a }->[1], 'CODE' );

throws_ok { add_to_wanted( 'a', qr{x}, sub {1})}
          qr/a is already defined as a file type/,
          "Duplicate";

throws_ok { add_to_wanted( undef, qr{x}, sub {1})}
          qr/Must provide a name to 'add_to_wanted\(\)'/,
          "name";

throws_ok { add_to_wanted( 'b', [], sub {1})}
          qr/Second argument to 'add_to_wanted\(\)' must be a regex/,
          "regex";

throws_ok { add_to_wanted( 'b', qr{x}, [])}
          qr/Third argument to 'add_to_wanted\(\)' must be a coderef/,
          "regex";

my $one = $CLASS->new('b');
isa_ok( $one, $CLASS );
is_deeply( $one->types, [ 'b' ], "Got provided" );

$one = $CLASS->new;
isa_ok( $one, $CLASS );
is_deeply( $one->types, [ 'a' ], "Got all" );

require Fennec::Runner::Root;
{
    no warnings 'redefine';
    sub Fennec::Runner::Root::get { return $_[0] }
    sub Fennec::Runner::Root::path { 't/fakeroots/files' }
    sub Fennec::Runner::get { return $_[0] };
    sub Fennec::Runner::ignore { return [] };
}

my @list = sort { $a->[1] cmp $b->[1] } $one->list;
like( $list[0]->[1], qr/good_file/, "First file" );
like( $list[1]->[1], qr/good_file_die/, "Second file" );
ok( !$list[2], "Only found 2 files" );

lives_ok { $one->load } "load does not die";

is( @{ $one->bad_files }, 1, "one file failed to load" );
is( $one->bad_files->[0]->[0], 't/fakeroots/files/t/good_file_die', "Correct file did not load" );
like( $one->bad_files->[0]->[1], qr/^died/, "Proper error" );

add_to_wanted( 'b', qr{good_file_die}, sub { 0; });
my $one = $CLASS->new('b');
lives_ok { $one->load } "load does not die";
is( @{ $one->bad_files }, 1, "one file failed to load" );
is( $one->bad_files->[0]->[0], 't/fakeroots/files/t/good_file_die', "Correct file did not load" );
like( $one->bad_files->[0]->[1], qr/Loader did not return true/, "Proper error" );

done_testing;
