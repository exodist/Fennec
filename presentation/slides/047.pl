




cases "Act the same in these cases" {
    my $self = shift;

    case a {
        my $self = shift;
        $self->reset_data( 'a' );
    }
    case b {
        my $self = shift;
        $self->reset_data( 'b' );
    }

    tests {
        my $self = shift;
        ok( $self->have_data, "have data" );
    }
    tests {
        my $self = shift;
        ok( $self->works, "it works" );
    }
}








