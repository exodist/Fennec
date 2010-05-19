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

    Fennec::Assert::Core->export_to( $pkg );
    my $self = bless( \$pkg, __PACKAGE__ );

    for my $load ( ___as_list( $proto{ use })) {
        $self->use( $load );
    }

    return $self;
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

sub use {
    my $self = shift;
    my ( $load, @args ) = @_;
    my $pkg = $self->class;

    if ( @args ) {
        eval "package $pkg; use $load \@args; 1" || die( $@ );
    }
    else {
        eval "package $pkg; use $load; 1" || die( $@ );
    }
    1;
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

=head1 NAME

Fennec::Assert::Core::Anonclass - Easily build a temporary class

=head1 DESCRIPTION

Sometimes you need a class that uses a module or implements some functionality
in order to test another module. This provides a simple way to do that.

=head1 SYNOPSIS

    use Fennec::Assert::Core::Anonclass;

    my $anonclass = anonclass(
        use => $package || \@packages
        isa => $base || \@bases,
        accessors => \@accessor_names,
        subs => {
            name => sub { ... },
            ...
        },
    );

    # can() and isa() check against the anonymous class, not the
    # Fennec::Assert::Core::Anonclass package.
    ok( $anonclass->can( ... ));
    ok( $anonclass->isa( ... ));

    # You can instanciate your class
    my $instance = $anonclass->new( ... );

    # You can use all core testing functions as methods on your object
    $instance->is_deeply( $want, $name );
    $instance->can_ok( @list );
    $instance->isa_ok( $base );

    1;

=head1 SCOPE WARNING

The anonymous class will be destroyed when the $anonclass object and all
instances fall out of scope. This will most likely never be a problem, but it
is important to know.

=head1 CLASS METHODS

=over 4

=item $instance = $anonclass->new( ... )

Create a new instance of the anonymous class. Will call any new() method
provided during anonclass construction, otherwise will bless a hashref
containing any params provided.

=item $subref = $anonclass->can( $name )

can() on an anonclass object will act against the blessed anonymous class, not
against the anonclass package.

=item $bool = $anonclass->isa( $package )

isa() on an anonclass object will act against the blessed anonymous class, not
against the anonclass package.

=item $package = $anonclass->class()

Return the full package name of the anonymous class. This will be a strange
looking package name with seemingly random characters at the end, but it is
valid until the anonclass object is destroyed.

=back

=head1 USER DOCUMENTATION

User documentation is for those who wish to use Fennec to write simple tests,
or manage a test suite for a project.

=over 4

=item L<Fennec::UserManual>

=back

=head1 DEVELOPER DOCUMENTATION

Developer documentation is for those who wish to extend Fennec, or contribute
to overall Fennec development.

=over 4

=item L<Fennec::DeveloperManual>

=back

=head1 API DOCUMENTATION

API Documentation covers object internals. See the POD within each individual
module.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
