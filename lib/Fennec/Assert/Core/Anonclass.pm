package Fennec::Assert::Core::Anonclass;
use strict;
use warnings;

use Fennec::Assert;
use Fennec::Util::Accessors;

use Fennec::Assert::Core;
use Scalar::Util qw/blessed reftype/;
use Carp;

our $ANON_PKG = 'AAAA';

util anonclass => sub {
    my %proto = @_;
    my $tail = $ANON_PKG++;
    my $pkg = 'Fennec::Assert::Core::Anonclass::__ANON__::' . $tail;
    $INC{ "Fennec/Assert/Core/Anonclass/__ANON__/$tail.pm" } = __FILE__;
    no strict 'refs';
    push @{ $pkg . '::ISA' } => ___as_list( $proto{ isa })
        if $proto{ isa };
    Fennec::Util::Accessors->build_accessors( $pkg, @{ $proto{ accessors }});
    for my $sub ( keys %{ $proto{ subs }}) {
        my $code = $proto{ subs }->{ $sub };
        *{ $pkg . '::' . $sub } = $code;
    }
    for my $load ( ___as_list( $proto{ use })) {
        eval "package $pkg; use $load; 1" || die( $@ );
    }
    Fennec::Assert::Core->export_to( $pkg );
    return bless( \$pkg, __PACKAGE__ );
};

sub ___as_list {
    my ($val) = @_;
    return () unless $val;
    return @$val if ref $val and ref $val eq 'ARRAY';
    return ($val);
}

sub new {
    my $in = shift;
    croak "You cannot init an instance of $in"
        unless blessed( $in );
    return $in->class->new( $in, @_ ) if $in->class->can( 'new' );
    return bless( { _keep_alive_ref_ => $in,  @_ }, $in->class );
}

sub can {
    my $in = shift;
    return $in->SUPER::can( @_ )
        unless blessed( $in );
    return $in->class->can( @_ );
}

sub isa {
    my $in = shift;
    return $in->SUPER::isa( @_ )
        unless blessed( $in );
    return $in->class->isa( @_ );
}

sub class {
    my $self = shift;
    return $$self;
}

sub DESTROY {
    my $self = shift;
    my $class = $self->class;
    my $sym = $class . '::';
    no strict 'refs';
    for my $thing (keys %$sym) {
        delete $sym->{$thing};
    }
}

1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
