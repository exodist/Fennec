package Fennec::EndRunner;
use strict;
use warnings;

my $RUNNER;

sub set_runner {
    $RUNNER = pop if @_;
    return $RUNNER;
}

END {
    return unless $RUNNER;
    return if $RUNNER->_skip_all;

    print STDERR <<"    EOT";

###############################################################################
#       **** It does not look like run_tests() was ever called! ****          #
#                                                                             #
#   As of Fennec 2 automatically-running standalone fennect tests are         #
#   deprecated. This descision was made because all run after run-time        #
#   methods are hacky and/or qwerky.                                          #
#                                                                             #
#   Since there are so many legacy Fennec tests that relied on this behavior  #
#   it has been carried forward in this deprecated form. An END block has     #
#   been used to display this message, and will next run your tests.          #
#                                                                             #
#   For most legacy tests this should work fine, however it may cause issues  #
#   with any tests that relied on other END blocks, or various hacky things.  #
#                                                                             #
#   DO NOT RELY ON THIS BEHAVIOR - It may go away in the near future.         #
###############################################################################

    EOT

    $RUNNER->run();
}

1;
