package Fennec::Tester::Threader;
use strict;
use warnings;
use Fennec::Util qw/add_accessors/;

add_accessors qw/pid max_files max_partitionss max_cases max_sets files partitions cases sets/;

sub new {
    my $class = shift;
    my %proto = @_;
    $proto{ pid } = $$;

    # if we got numbers for any 1 or more types use them, with 1 for others
    # If we got a maximum only, then divide it into the 4 types.

    return bless( \%proto, $class );
}

sub thread {
    my $self = shift;
    my ( $type, $code, @args ) = @_;
    $type .= 's';
    my $msub = "max_$type";
    my $max = $self->$msub || 1;
    return $self->_fork( $type, $max, $code, \@args ) if $max > 1 || $type = 'forks';
    return $code->( @args );
}

sub _fork {
    my $self = shift;
    my ( $type, $max, $code, $args ) = @_;

    # This will block if necessary
    my $tid = $self_->get_tid;

    my $pid = fork();
    return $self->tid_pid( $tid, $pid ) if $pid;
    $code->( @$args );
    # This needs to take care of cleanup of this processes children as well as
    # the output plugin stuff.
    $self->cleanup;
    Fennec::Tester->_subprocess_exit;
}

sub get_tid {
    my $self = shift;


    # WHEN BLOCKING ON PARENT WE MUST RUN THE LISTENER ITERATE METHOD AT A
    # REGULAR INTERVAL OR NO PROCESSES WILL EVER RETURN.
}

# Get or set the pid for a tid.
sub tid_pid {

}

1;
