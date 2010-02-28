package Test::Suite::TestBuilderImposter;
use strict;
use warnings;
use Test::Builder;
use Carp;
use base 'Exporter';

my @STACK;
our @EXPORT = qw/wrap_sub/;

sub new { return bless( {}, $_[0] ) }

sub wrap_sub {
    my ($sub) = @_;
    croak "wrap_sub called without sub" unless $sub;
    unless ( ref $sub and ref $sub eq 'CODE' ) {
        my ( $caller ) = caller;
        $sub = $caller->can( $sub );
    }

    my $proto = prototype( $sub );

    # No prototype
    return sub {
        $sub->( \@_ );
        return @{ last_result() };
    } unless $proto;

    # Prototype
    return eval "
        sub($proto) {
            \$sub->( \@_ );
            return \@{ last_result() };
        }
    " || die($@);
}

sub last_result {
    pop @STACK;
}

sub ok{
    shift;
    my ( $result, $name ) = @_;
    push @STACK => [ $result, $name ];
}

sub diag{
    my $class = shift;
    Test::Suite::PluginTester::push_diag( @_ );
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

