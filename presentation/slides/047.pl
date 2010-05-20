







cases "Act the same in these cases" {

    case a {
        $self->reset_data( 'a' );
    }
    case b {
        $self->reset_data( 'b' );
    }

    tests {
        ok( $self->have_data, "have data" );
    }
    tests {
        ok( $self->works, "it works" );
    }
}










