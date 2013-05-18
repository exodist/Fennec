package Fennec::Collector;
use strict;
use warnings;

use Carp qw/confess/;
use Fennec::Util qw/accessors require_module/;

accessors qw/test_count test_failed/;

my @PREFERENCE = qw{
    Fennec::Collector::TB::TempFiles
};

sub ok           { confess "Must override ok" }
sub diag         { confess "Must override diag" }
sub end_pid      { confess "Must override end_pid" }
sub collect      { confess "Must override collect" }
sub validate_env { confess "must override validate_env" }

sub update_wfmeta { }
sub finish        { }
sub initialize    { }

sub new {
    my $class = shift;

    confess "Must override new" unless $class eq __PACKAGE__;

    my @preference = @_ ? @_ : @PREFERENCE;

    for my $module (@preference) {
        require_module $module;

        next unless $module->validate_env;
        my $collector = $module->new;
        $collector->initialize;
        return $collector;
    }

    die "Could not find a valid collector!";
}

sub inc_test_count {
    my $self = shift;
    my $count = $self->test_count || 0;
    $self->test_count( $count + 1 );
}

sub inc_test_failed {
    my $self = shift;
    my $count = $self->test_failed || 0;
    $self->test_failed( $count + 1 );
}

1;

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license (GPL and Artistic).

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
