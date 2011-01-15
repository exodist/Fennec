package Fennec::Meta;
use strict;
use warnings;

use Fennec::Util qw/array_accessors accessors/;

accessors qw/utils fennec class file start_line end_line name/;
array_accessors qw/ workflows tests wraps /;

1;
