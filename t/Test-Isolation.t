#!/usr/bin/perl

use Fennec parallel => 0, test_sort => 'random';
use Cwd qw(abs_path);

my $Original_Cwd;
before_all name => sub {
    $Original_Cwd = abs_path;
    note "Before All $$ $Original_Cwd";
};

tests "chdir 1" => sub {
    note "$$ $Original_Cwd";
    is $Original_Cwd, abs_path;
    chdir "..";
};

tests "chdir 2" => sub {
    note "$$ $Original_Cwd";
    is $Original_Cwd, abs_path;
    chdir "t";
};

done_testing;
