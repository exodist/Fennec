package Test::Suite::TestBuilderImposter;
use strict;
use warnings;
use Test::Builder;
use Carp;
use base 'Exporter';

our @RESULTS;
our @DIAGS;

our @EXPORT = qw/wrap_sub/;

sub new { return bless( {}, $_[0] ) }

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
        local @RESULTS;
        local @DIAGS;
        $sub->( @_ );
        return ( @{ last_result() }, @DIAGS );
    };

    # No prototype
    return $new unless $proto;

    # Prototype
    return eval "sub($proto) { \$new->( \@_ ) }" || die($@);
}

sub last_result {
    pop @RESULTS;
}

sub ok{
    shift;
    my ( $result, $name ) = @_;
    push @RESULTS => [ $result, $name ];
}

sub diag{
    my $class = shift;
    push @DIAGS => @_;
}

sub isa {
    my $class = shift;
    my ( $want ) = @_;
    return 1 if $want eq 'Test::Builder';
    return $class->SUPER::isa( @_ );
}

sub can {
    my $class = shift;
    my ($name) = @_;
    no strict 'refs';
    return \&$name
        || sub { croak 'TestBuilderImposter->' . $name . '() is not yet implemented' };
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $class = shift;
    my $name = $AUTOLOAD;
    $name =~ s/^.*:([^:]+)$/$1/g;
    my $sub = $class->can( $1 );
    goto &$sub;
}

sub DESTROY {}

1;

