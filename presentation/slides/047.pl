







cases "Act the same in these cases" {

    case a {
        $self->reset_data( 'a' );
    }
    case b {
        $self->reset_data( 'b' );
    }

    tests has_data {
        ok( $self->have_data, "have data" );
    }
    tests works {
        ok( $self->works, "it works" );
    }
}










