package Test::Suite::TestBuilderImposter;
use strict;
use warnings;
use Test::Builder;
use Carp;
use base qw/Exporter Test::Builder/;

our @EXPORT = qw/wrap_sub/;

sub wrap_sub {
    my ($sub) = @_;
    croak "wrap_sub called without sub" unless $sub;
    unless ( ref $sub and ref $sub eq 'CODE' ) {
        my ( $caller ) = caller;
        $sub = $caller->can( $sub );
    }
    croak( "Could not find code" )
        unless $sub && ref $sub eq 'CODE';

    my $proto = prototype( $sub );

    my $new = sub {
        my $result;
        my @diags;

        no warnings 'redefine';
        local *Test::Builder::ok = sub {
            shift;
            my ( $ok, $name ) = @_;
            $result = [ $ok, $name ];
        };
        local *Test::Builder::diag = sub {
            my $class = shift;
            push @diags => @_;
        };

        $sub->( @_ );

        return ( @$result, @diags );
    };

    # No prototype
    return $new unless $proto;

    # Prototype
    return eval "sub($proto) { \$new->( \@_ ) }" || die($@);
}

1;
