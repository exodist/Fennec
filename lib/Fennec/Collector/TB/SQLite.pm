package Fennec::Collector::TB::SQLite;
use strict;
use warnings;

use base 'Fennec::Collector::TB';
use Fennec::Util qw/accessors/;
use File::Temp;
use Data::Dumper;

accessors qw/last_source filename _pid/;

sub validate_env {
    return eval {
        require DBI;
        require DBD::SQLite;
        1;
    };
}

sub new {
    my $class = shift;
    require DBD::SQLite;
    my $fh = File::Temp->new( UNLINK => 0 );
    my $fname = $fh->filename;
    close($fh);

    my $self = bless {
        filename    => $fname,
        dbh_pid     => -1,
        last_source => "",
        _pid        => $$,
    }, $class;

    $self->init_db();

    return $self;
}

sub init_db {
    my $self = shift;
    my $dbh  = $self->dbh;

    $dbh->do( <<"    EOT" );
CREATE TABLE result(
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    pid        INTEGER NOT NULL,
    source     TEXT    NOT NULL,
    line       TEXT    NOT NULL,
    stream     TEXT    NOT NULL,
    part       INTEGER NOT NULL,
    ready      INTEGER NOT NULL DEFAULT 0,
    collected  INTEGER NOT NULL DEFAULT 0
)
    EOT
}

sub dbh {
    my $self = shift;

    if ( $self->{dbh_pid} != $$ ) {
        my $fname = $self->filename;
        $self->{dbh_pid} = $$;
        $self->{dbh}     = DBI->connect(
            "dbi:SQLite:dbname=$fname",
            "", "",
            {
                RaiseError => 1,
                AutoCommit => 1,
            }
        ) || die "Could not create db handle!";
    }

    return $self->{dbh};
}

sub report {
    my $self   = shift;
    my %params = @_;

    my $dbh = $self->dbh;

    if ( $params{source} ne $self->last_source ) {
        $self->_flush;
        $self->last_source( $params{source} );
    }

    for my $item ( @{$params{data}} ) {
        my $count = 1;
        for my $part ( split /\r?\n/, $item ) {
            my $sth = $dbh->prepare(
                'INSERT INTO result( pid, source, line, stream, part ) VALUES( ?, ?, ?, ?, ? )',
            );
            $sth->execute( $$, $params{source}, $part, $params{name}, $count++ );
        }
    }
}

sub _flush {
    my $self = shift;

    return unless $self->last_source;

    my $sth = $self->dbh->prepare('UPDATE result SET ready = 1 WHERE source = ? AND pid = ?');
    $sth->execute( $self->last_source, $$ );
}

sub collect {
    my $self = shift;

    my $dbh = $self->dbh;

    my $sth = $dbh->prepare( <<'    EOT' );
        SELECT *
        FROM result
        WHERE ready != 0
          AND collected = 0
        ORDER BY pid, source, part ASC
    EOT

    $sth->execute;

    my @done;
    while ( my $row = $sth->fetchrow_hashref ) {
        $self->render( $row->{stream}, $row->{line} );
        push @done => $row;
    }

    for my $row (@done) {
        $sth = $dbh->prepare('UPDATE result SET collected = 1 WHERE id = ?');
        $sth->execute( $row->{id} );
    }
}

sub finish {
    my $self = shift;
    $self->_flush;
    $self->last_source('');

    return unless $self->_pid == $$;
    $self->collect;
    $self->SUPER::finish();

    my $sth = $self->dbh->prepare('SELECT * FROM result WHERE collected = 0');
    $sth->execute;
    my $count = 0;
    while ( my $row = $sth->fetchrow_hashref ) {
        use Data::Dumper;
        print STDERR Dumper($row);
        $count++;
    }
    die "Not all results were processed!" if $count;
}

sub end_pid {
    my $self = shift;
    $self->_flush;
}

1;
