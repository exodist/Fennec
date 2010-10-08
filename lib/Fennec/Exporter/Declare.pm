package Fennec::Exporter::Declare;
use strict;
use warnings;

use Carp;
use Scalar::Util qw/blessed/;
use Devel::Declare::Interface;
use Fennec::Exporter::Declare::Export;

our @CARP_NOT = ( __PACKAGE__ );
our %PARSERS = ( export => Devel::Declare::Interface::get_parser('export'));
our @EXPORT = qw/ export_to import /;
our @EXPORT_OK = qw/
    exports export_oks parsers exporter_tags all_exports gen_exports
    gen_export_oks all_gen_exports
/;
our %EXPORTER_TAGS = (
    all => sub {
        keys( %{ all_exports( @_ )    }),
        keys( %{ all_gen_exports( @_ )}),
    },
    default => sub {
        keys( %{ exports( @_ )    }),
        keys( %{ gen_exports( @_ )}),
    },
    DEFAULT => sub {
        keys( %{ exports( @_ )    }),
        keys( %{ gen_exports( @_ )}),
    },
    extended => sub {
        keys( %{ export_oks( @_ )    }),
        keys( %{ gen_export_oks( @_ )}),
    },
);

export( 'export',        'export' );
export( 'export_ok',     'export' );
export( 'gen_export',    'export' );
export( 'gen_export_ok', 'export' );

sub import {
    my $class = shift;
    my $caller = caller;
    my ( $imports, $specs ) = _import_args( @_ );

    export_to( $class, $caller, $specs, @$imports );

    if ( $specs->{extend} ) {
        no strict 'refs';
        no warnings 'once';
        push @{ $caller . '::ISA' } => $class
            unless grep { $_ eq $class } @{ $caller . '::ISA' };

        $caller->export( $_ ) for
            grep { $caller->can( $_ ) }
                keys %{ exports($class)};

        $caller->export_ok( $_ ) for
            grep { $caller->can( $_ ) }
                keys %{ export_oks($class)};
    }

    return $class->_import( $caller, $specs )
        if $class->can( '_import' );
}

sub _import_args {
    my ( @imports, %specs );
    for my $item ( @_ ) {
        if ( ref $item && ref $item eq 'HASH' ) {
            $specs{ rename } = $item;
        }
        elsif ( $item =~ m/^(!?):([^:]*)(?::(.*))?$/ ) {
            $specs{ $2 } = [ !$1, $3 || 1 ];
        }
        else {
            push @imports => $item;
        }
    }
    return( \@imports, \%specs );
}

sub exports {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    return {
        ( map { $_ => $_ } @{ $class . '::EXPORT' }),
        %{ $class . '::EXPORT' },
    };
}

sub export_oks {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    return {
        ( map { $_ => $_ } @{ $class . '::EXPORT_OK' }),
        %{ $class . '::EXPORT_OK' },
    };
}

sub all_exports {
    my $class = shift;
    return {
        %{ export_oks( $class ) },
        %{ exports( $class )    },
    };
}

sub all_gen_exports {
    my $class = shift;
    return {
        %{ gen_export_oks( $class ) },
        %{ gen_exports( $class )    },
    };
}

sub gen_exports {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    \%{ $class . '::GEN_EXPORT' };
}

sub gen_export_oks {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    \%{ $class . '::GEN_EXPORT_OK' };
}

sub parsers {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    return { %{ $class . '::PARSERS' } };
}

sub exporter_tags {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    return {
        %EXPORTER_TAGS,
        %{ $class . '::EXPORTER_TAGS' }
    };
}

sub _tag_list {
    my ( $class, $tag ) = @_;
    my $list = exporter_tags( $class )->{ $tag };
    return unless $list;

    return ref $list eq 'CODE'
        ? $list->($class)
        : @$list;
}

sub _normalize_import_list {
    my ( $class, $specs, @list ) = @_;
    my ( %include, %exclude );

    return $class->normalize_import_list(
        $class, $specs, @list
    ) if $class->can( 'normalize_import_list' );

    for my $tag ( keys %{ exporter_tags( $class )}) {
        next unless my $spec = $specs->{$tag};

        if ( $spec->[0] )
          { $include{ $_ }++ for _tag_list( $class, $tag )}
        else
          { $exclude{ $_ }++ for _tag_list( $class, $tag )}
    }

    @list = _tag_list( $class, 'default' )
        unless @list || keys %include;

    for my $item ( @list ) {
        if ( $item =~ m/^!(.*)$/ )
          { $exclude{ $1 }++ }
        else
          { $include{ $item }++ }
    }

    return grep { !$exclude{ $_ } } keys %include;
}

sub export_to {
    my ( $class, $dest, $specs, @list ) = @_;
    $specs = { prefix => [ 1, $specs ]}
        if $specs && !ref $specs;
    $specs ||= {};

    my $parsers = parsers( $class );
    my $all_exports = all_exports( $class );
    my $generated = all_gen_exports( $class );

    @list = _normalize_import_list( $class, $specs, @list );

    for my $name ( @list ) {
        my $item = $all_exports->{ $name }
            || ( $generated->{$name}
                ? $generated->{$name}->( $class, $dest )
                : croak "'$name' is not exported by $class."
               );

        $item = _get_item_ref( $class, $item ) unless ref $item;

        croak "Could not find '$name' in $class for export. Got: "
              . ( defined( $item ) ? "'$item'" : 'undef' )
              unless $item && ref($item);

        {
            no strict 'refs';
            no warnings 'once';
            *{ join( '::',
                $dest,
                _export_name( $class, $name, $specs ),
            )} = $item;
        }

        my $parser = $parsers->{ $name };
        Devel::Declare::Interface::enhance(
            $dest,
            $name,
            $parser,
        ) if $parser;
    }
}

sub _export_name {
    my $class = shift;
    my ( $name, $specs ) = @_;

    return $class->export_name( $name, $specs )
        if $class->can( 'export_name' );

    my $calculated = ( $specs->{rename} && $specs->{rename}->{ $name })
        ? $specs->{rename}->{ $name }
        : $specs->{prefix}
            ? $specs->{prefix}->[1] . $name
            : $name;

    $calculated =~ s/^[\$\%\@]//g;

    return $calculated;
}

sub _normalize_export_args {
    my ( $exporter, $item );

    $item = pop( @_ ) if ref( $_[-1] );

    if ( $_[0] ) {
        my $blessed = blessed( $_[0] );
        my $ref = ref( $_[0] );
        my $is_var = (!$ref && $_[0] =~ m/^[\$\%\@]\w+[\w\d_]*$/) ? 1 : 0;
        my $can_export = $is_var ? 0 : $_[0]->can( 'export' );

        $exporter = shift( @_ ) if $blessed || $can_export;
    }

    $exporter = blessed( $exporter ) || $exporter || undef;
    my ( $name, $parser ) = @_;

    return ( $name, $exporter, $item, $parser );
}

sub _export {
    my ( $type, $caller, @args ) = @_;
    my ( $name, $exporter, $item, $parser ) = _normalize_export_args( @args );
    $exporter ||= $caller;

    croak( "You must provide a name to $type\()" )
        unless $name;

    $item ||= _get_item_ref( $exporter, $name );
    croak( "No ref found in '$exporter' for exported item '$name'" )
        unless $item;

    _verify_item_ref( $name, $item );

    my $export;
    my $parsers;
    {
        no strict 'refs';
        no warnings 'once';
        $export = \%{ $exporter . '::' . uc($type) };
        $parsers = \%{ $exporter . '::PARSERS' };
    }
    $export->{ $name } = $item;
    $parsers->{ $name } = $parser if $parser;
}

sub _get_item_ref {
    my ( $package, $item ) = @_;
    my ( $type, $name ) = ( $item =~ m/^([\$\%\@])(\w+[\w\d_]*)$/ );

    return $package->can( $item )
        unless $type && $name;

    my $varstring = "${type}\{'$package\::$name'\}";
    return eval "no strict 'refs'; \\$varstring";
}

sub _verify_item_ref {
    my ( $name, $item ) = @_;
    my ( $type ) = ( $item =~ m/^([\$\%\@])$/ );
    $type ||= '&';
    1;
}

sub export {
    my $caller = caller;
    _export( 'export', $caller, @_ );
}

sub export_ok {
    my $caller = caller;
    _export( 'export_ok', $caller, @_ );
}

sub gen_export {
    my $caller = caller;
    _export( 'gen_export', $caller, @_ );
}

sub gen_export_ok {
    my $caller = caller;
    _export( 'gen_export_ok', $caller, @_ );
}

1;

__END__

=head1 NAME

Fennec::Exporter::Declare - Declarative exports and simple Devel-Declare interface.

=head1 DESCRIPTION

Declarative function exporting. You can export subs as usual with @EXPORT, or
export anonymous subs under whatever name you want. You can also extend
Fennec::Exporter::Declare very easily.

Exporter-Declare also provides a friendly interface to L<Devel::Declare> magic.
With L<Devel::Declare::Parser> and its parser library, you can write
L<Devel::Declare> enhanced functions without directly using Devel-Declare.

Exporter-Declare also supports tags, optional exports, and exported variables
just like L<Exporter>.  An addition you can prefix or rename imports at import
time.

B<Fennec::Exporter::Declare should be usable as a drop-in replacement for L<Exporter>>

=head1 BASIC SYNOPSIS

=head2 EXPORTING

    package My::Exporter;
    use strict;
    use warnings;
    use Fennec::Exporter::Declare;

    # works as expected
    our @EXPORT = qw/a/;
    our @EXPORT_OK = qw/f/;
    our @EXPORT_TAGS = (
        main => \@EXPORT,
        other => \@EXPORT_OK,
        mylist => [ ... ],
        # Bonus!
        dynamic => sub { $class = shift; return ( qw/a b/ )}
    );

    our $_ID = 1;
    # Fancy export is generated each time
    our %GEN_EXPORT_OK = ( ... );
    our %GEN_EXPORT = (
        importer_id => sub {
            my ( $exporting_class, $importing_class ) = @_;
            my $id = _ID++;
            return sub { $id };
        }
    );

    sub a { 'a' }

    # Declare an anonymous export
    export b => sub { 'b' };
    export( 'c', sub { 'c' });

    export 'd';
    sub d { 'd' }

    export_ok 'e';
    sub e { 'e' }

    sub f { 'f' }

    export_ok g => sub g { 'g' }

    # declarative generated export
    {
        my $alpha = 'A';
        # can also use gen_export_ok
        gen_export unique_alpha => sub {
            my ( $exporting_class, $importing_class ) = @_;
            my $uniq = $alpha++;
            return sub { $uniq };
        }
    }

    1;

=head2 BASIC IMPORTING

    package My::Consumer;
    use strict;
    use warnings;
    use My::Exporter;

    a(); #calls My::Consumer::a()
    e(); # Will die, e() is in export_ok, not export

=head1 ENHANCED INTERFACE SYNOPSIS

Notice, no need for '=> sub', and trailing semicolon is optional.

    package MyPackage;
    use strict;
    use warnings;
    use Fennec::Exporter::Declare;

    # Declare an anonymous export
    export b { 'b' }

    export c {
        'c'
    }

    1;

=head1 EXPORTING DEVEL-DECLARE INTERFACES SYNOPSIS

To export Devel-Declare magic you specify a parser as a second parameter to
export(). Please see the PARSERS section for more information about each
parser.

    package MyPackage;
    use strict;
    use warnings;
    use Fennec::Exporter::Declare;

    export sl sublike {
        # $name and $sub are automatically shifted for you.
        ...
    }

    export mth method {
        # $name and $sub are automatically shifted for you.
        ...
    }

    export cb codeblock {
        # $sub is automatically shifted for you.
        ...
    }

    export beg begin {
        my @args = @_;
        ...
    };

    # Inject something into the start of the code block
    export injected method ( inject => 'my $arg2 = shift; ' ) { ... }

Then to use those in the importing class:

    use strict;
    use warnings;
    use MyPackage;

    sl name { ... }

    mth name {
        # $self is automatically shifted for you.
        ...
    }

    cb { ... }

    # Same as BEGIN { beg(@args) };
    beg( @args );

=head1 MANY FACES OF EXPORT

The export functions are the magical interface. They can be used in many forms.
This is a complete guide to all forms. In practice a small subset is probably
all most tools will use.

=over 4

=item our @EXPORT = @names;

=item our @EXPORT_OK = @names;

=item our %GEN_EXPORT = ( name => \&generator, ... );

=item our %GEN_EXPORT_OK = ( name => \&generator, ... );

Technically your not actually using the function here, but it is worth noting
that use of a package variable '@EXPORT' works just like L<Exporter>.

=item export($name)

=item export_ok($name)

=item gen_export($name)

=item gen_export_ok($name)

Export the sub specified by the string $name. This sub must be defined in the
current package. Those with the 'gen_' prefix will treat the referenced sub as
a generator.

=item export($name, sub { ... })

=item export_ok($name, sub { ... })

=item export name => sub { ... }

=item export_ok name => sub { ... }

=item gen_export($name, sub { ... })

=item gen_export_ok($name, sub { ... })

=item gen_export name => sub { ... }

=item gen_export_ok name => sub { ... }

=item export name { ... }

=item export_ok name { ... }

=item gen_export name { ... }

=item gen_export_ok name { ... }

Export the coderef under the specified name. In the second 2 forms an ending
semicolon is optional, as well name can be quoted in single or double quotes,
or left as a bareword.

=item export( $name, $parser )

=item export_ok( $name, $parser )

=item gen_export( $name, $parser )

=item gen_export_ok( $name, $parser )

Export the sub specified by the string $name, applying the magic from the
specified parser whenever the function is called by a class that imports it.

=item export( $name, $parser, sub { ... })

=item export_ok( $name, $parser, sub { ... })

=item gen_export( $name, $parser, sub { ... })

=item gen_export_ok( $name, $parser, sub { ... })

=item export name parser { ... }

=item export_ok name parser { ... }

=item gen_export name parser { ... }

=item gen_export_ok name parser { ... }

Export the coderef under the specified name, applying the magic from the
specified parser whenever the function is called by a class that imports it. In
the second form name and parser can be quoted in single or double quotes, or
left as a bareword.

=item export name ( ... ) { ... }

=item export_ok name ( ... ) { ... }

=item gen_export name ( ... ) { ... }

=item gen_export_ok name ( ... ) { ... }

same as 'export name { ... }' except that parameters can be passed into the
parser. Currently you cannot put any variables in the ( ... ) as it will be
evaluated as a string outside of any closures - This may be fixed in the
future.

Name can be a quoted string or a bareword.

=item export name parser ( ... ) { ... }

=item export_ok name parser ( ... ) { ... }

=item gen_export name parser ( ... ) { ... }

=item gen_export_ok name parser ( ... ) { ... }

same as 'export name parser { ... }' except that parameters can be passed into
the parser. Currently you cannot put any variables in the ( ... ) as it will be
evaluated as a string outside of any closures - This may be fixed in the
future.

Name and parser can be a quoted string or a bareword.

=item $class->export( $name )

=item $class->export_ok( $name )

=item $class->gen_export( $name )

=item $class->gen_export_ok( $name )

Method form of 'export( $name )'. $name must be the name of a subroutine in the
package $class. The export will be added as an export of $class.

=item $class->export( $name, sub { ... })

=item $class->export_ok( $name, sub { ... })

=item $class->gen_export( $name, sub { ... })

=item $class->gen_export_ok( $name, sub { ... })

Method form of 'export( $name, \&code )'. The export will be added as an export
of $class.

=item $class->export( $name, $parser )

=item $class->export_ok( $name, $parser )

=item $class->gen_export( $name, $parser )

=item $class->gen_export_ok( $name, $parser )

Method form of 'export( $name, $parser )'. $name must be the name of a
subroutine in the package $class. The export will be added as an export of
$class.

=item $class->export( $name, $parser, sub { ... })

=item $class->export_ok( $name, $parser, sub { ... })

=item $class->gen_export( $name, $parser, sub { ... })

=item $class->gen_export_ok( $name, $parser, sub { ... })

Method form of 'export( $name, $parser, \&code )'. The export will be added as
an export of $class.

=back

=head1 IMPORTER SYNOPSIS

=head2 NORMAL

    package MyThing;
    use MyThingThatExports;

=head2 CUSTOMISING

    package My::Consumer;
    use strict;
    use warnings;
    use My::Exporter qw/ a !f :prefix:my_ :other !:mylist /,
                     { a => 'apple' };

    apple(); #calls My::Consumer::a(), renamed via the hash above

    f(); # Will die, !f above means do not import

    my_g(); # calls My::Consumer::e(), prefix applied, imported via :other

    1;

=over 4

=item 'export_name'

If you list an export it will be imported (unless it appears in a negated form)

=item '!export_name'

The export will not be imported

=item { export_name => 'new_name' }

Rename an import.

=item ':prefix:VALUE'

Specify that all imports should be renamed with the given prefix, unless they
are already renamed via a rename hash.

=item ':tag'

=item '!:tag'

Import all the exports listed by $EXPORT_TAGS{tag}. ! will negate the list. all
tag names are valid unless they conflict with a specal keyword such as 'prefix'
or 'extend'.

=back

=head1 Extending (Writing your own Exporter-Declare)

Doing this will make it so that importing your package will not only import
your exports, but it will also make the importing package capable of exporting
subs.

    package MyExporterDeclare;
    use strict;
    use warnings;
    use Fennec::Exporter::Declare ':extend';

    export my_export export {
        my ( $name, $sub ) = @_;
        export( $name, $sub );
    }

=head1 PARSERS

=head2 Writing custom parsers

See L<Devel::Declare::Parser>

=head2 Provided Parsers

=over 4

=item L<Devel::Declare::Parser::Export>

Used for functions that export, accepting a name, a parser, and options.

=item L<Devel::Declare::Parser::Sublike>

Things that act like 'sub name {}'

=item L<Devel::Declare::Parser::Method>

Same ad Sublike except codeblocks have $self automatically shifted off.

=item L<Devel::Declare::Parser::Codeblock>

Things that take a single codeblock as an arg. Like defining sub mysub(&)
except that you do not need a semicolon at the end.

=item L<Devel::Declare::Parser::Begin>

Define a sub that works like 'use' in that it runs at compile time (like
wrapping it in BEGIN{})

This requires L<Devel::BeginLift>.

=back

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greator framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
