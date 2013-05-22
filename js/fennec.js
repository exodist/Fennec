$( function() {
    $( '.nav' ).click( function() {
        var item = $(this)

        $('#subnav ul').empty();
        $('ul.second_subnav').detach();
        $('#view').empty();
        $('#error_window').click( function() {
            $(this).hide();
        });

        jQuery.ajax(
            item.attr( 'id' ) + '.html',
            {
                dataType: 'html',
                success: function( data ) {
                    $( '.nav' ).removeClass( 'active' )
                    item.addClass( 'active' )

                    build_content( data );
                    fixView();
                },
                error: function() {
                    $( '#error_window' ).show();
                    $( '#error_window ul.errors' ).append( "<li>Error loading page</li>" )
                    $( '.nav' ).removeClass( 'active' )
                    item.addClass( 'active' )
                    fixView();
                }
            }
        )
    });

    var hash = window.location.hash
    if ( hash ) {
        var page = hash.split('-');
        $( page[0] ).trigger( 'click' )
    }
    else {
        $( '#fennec' ).trigger( 'click' )
    }

    var navstate = 1;
    $('#nonav').click( function() {
        if ( navstate ) {
            navstate = 0;
            $('#view').addClass( 'nonav' );
            $('#subnav').addClass( 'nonav' );
            $('ul.second_subnav').addClass( 'nonav' );
            $(this).addClass( 'nonav' );
            $(this).text( '' );
        }
        else {
            navstate = 1;
            $('#view').removeClass( 'nonav' );
            $('#subnav').removeClass( 'nonav' );
            $('ul.second_subnav').removeClass( 'nonav' );
            $(this).removeClass( 'nonav' );
            $(this).text( 'Hide Navigation' );
        }
    });
})

function fixView() {
    var height = $('#subnav').outerHeight();
    if ( height < 350 ) height = 350;
    $('#view').css( 'min-height', height );
}

function build_content( data ) {
    var view = $( '#view' );
    var subnav = $( 'ul#main_subnav' );

    var hash = window.location.hash;
    if ( !hash ) hash = '#fennec';
    var nav = hash.split('-');

    var new_stuff = $( '<div></div>' );
    new_stuff.html( data );
    $(new_stuff).find( 'dl.listnav' ).each( function() {
        $(this).children('dt').each( function() {
            var id = $(this).attr( 'id' );
            var dt = $(this);
            var dd = $(this).next();
            var navitem = $(
                '<li id="' + id + '"><a href="' + nav[0] + '-' + id + '">' + dt.html() + '</a></li>'
            );
            var classes = dd.attr( 'class' );
            var viewitem = $(
                '<div style="display: none" class="' + classes + '">' + dd.html() + '</div>'
            );

            process( id, viewitem );

            var normal_click = function() {
                view.children().hide();
                $('ul.second_subnav').hide();
                subnav.children().removeClass( 'active' );
                viewitem.show();
                var sn = $('ul#SN-' + id);
                if ( sn.length ) {
                    sn.show();
                    sn.children().removeClass('active');
                    if ( sn.children().length > 4 ) {
                        subnav.children().hide();
                        navitem.unbind( 'click' );
                        navitem.click( function() {
                            subnav.children().show();
                            navitem.unbind( 'click' );
                            navitem.click( normal_click );
                            fixView();
                        });
                    }
                    sn.children().first().click();
                }
                navitem.addClass( 'active' );
                navitem.show();
                fixView();
            };

            navitem.click( normal_click );

            subnav.append( navitem );
            view.append( viewitem );
        });

        if ( nav[1] ) {
            $( '#' + nav[1] ).trigger( 'click' );
            $('ul#SN-' + nav[1]).each( function() {
                $(this).show();
                if ( nav[2] ) {
                    $(this).find( '#' + nav[2] ).trigger( 'click' );
                }
            });
        }
        else {
            subnav.children().first().trigger( 'click' );
        }
    })
}

function process( id, container ) {
    container.find( 'div.symbol_list' ).each( function() {
        var list = $(this);
        jQuery.ajax(
            list.attr( 'src' ),
            {
                dataType: 'json',
                success: function( data ) {
                    list.replaceWith( build_symbol_list( data ));
                    fixView();
                },
                error: function(blah, message1, message2) {
                    $( '#error_window' ).show();
                    $( '#error_window ul.errors' ).append( "<li>Error loading " + list.attr( 'src' ) + "</li>" )
                    fixView();
                }
            }
        )
    });

    container.find( 'dl.sub_list' ).each( function() {
        $(this).detach();
        build_sub_list( id, $(this) );
        fixView();
    });

    process_samples( container );
}

function process_samples( container ) {
    container.find( 'script.code' ).each( function() {
        $(this).replaceWith( build_code( $(this).text() ));
    });

    container.find( 'div.code' ).each( function() {
        var list = $(this);
        jQuery.ajax(
            list.attr( 'src' ),
            {
                dataType: 'text',
                success: function( data ) {
                    list.replaceWith( build_code( data ));
                    fixView();
                    start_debugger();
                },
                error: function(blah, message1, message2) {
                    $( '#error_window' ).show();
                    $( '#error_window ul.errors' ).append( "<li>Error loading " + list.attr( 'src' ) + "</li>" )
                    fixView();
                }
            }
        )
    });

    container.find( 'div.output' ).each( function() {
        var list = $(this);
        jQuery.ajax(
            list.attr( 'src' ),
            {
                dataType: 'text',
                success: function( data ) {
                    list.replaceWith( build_output( data ));
                    fixView();
                    start_debugger();
                },
                error: function(blah, message1, message2) {
                    $( '#error_window' ).show();
                    $( '#error_window ul.errors' ).append( "<li>Error loading " + list.attr( 'src' ) + "</li>" )
                    fixView();
                }
            }
        )
    });

    container.find( 'div.vim' ).each( function() {
        var list = $(this);
        jQuery.ajax(
            list.attr( 'src' ),
            {
                dataType: 'text',
                success: function( data ) {
                    list.replaceWith( build_vim( data ));
                    fixView();
                    start_debugger();
                },
                error: function(blah, message1, message2) {
                    $( '#error_window' ).show();
                    $( '#error_window ul.errors' ).append( "<li>Error loading " + list.attr( 'src' ) + "</li>" )
                    fixView();
                }
            }
        )
    });
}

function build_code( data ) {
    var brush = new SyntaxHighlighter.brushes.Perl();

    brush.init({ toolbar: false });
    return brush.getHtml( data );
}

function build_output( data ) {
    var brush = new SyntaxHighlighter.brushes.TAP();

    brush.init({ toolbar: false });
    return brush.getHtml( data );
}

function build_vim( data ) {
    var brush = new SyntaxHighlighter.brushes.Vimscript();

    brush.init({ toolbar: false });
    return brush.getHtml( data );
}


function build_sub_list( pid, list ) {
    var subnav = $( '<ul id="SN-' + pid + '" style="display: none;" class="second_subnav listnav"></ul>' );

    var hash = window.location.hash;
    if ( !hash ) hash = '#fennec';
    var nav = hash.split('-');

    list.find( 'dt' ).each( function() {
        var navkey = $(this).text();
        var section = $(this).next();
        process_samples( section );
        build_sub_list_item( pid, navkey, section, nav, subnav );
    });

    $("#subnav").append( subnav );
}

function build_sub_list_item( pid, navkey, section, nav, subnav ) {
    var navitem = $(
        '<li id="' + navkey + '"><a href="' + nav[0] + '-' + pid + '-' + navkey + '">' + navkey + '</a></li>'
    );
    var viewitem = $(
        '<div style="display: none"><h2>' + navkey + '</h2></div>'
    );
    viewitem.append( section );

    navitem.click( function() {
        $('#view').children().hide();
        subnav.children().removeClass( 'active' );
        navitem.addClass( 'active' );
        viewitem.show();
        fixView();
    });

    subnav.append( navitem );
    $('#view').append( viewitem );
}

function build_symbol_list( data ) {
    var table = $( '<table class="symbol_list"><tbody><tr><th>Name</th><th>Description &nbsp;&nbsp; <small>(Click a row for usage details)</small</th></tr></tbody></table>' );
    for (key in data) {
        var name = data[key]['name'];
        if ( !name ) name = key;
        var row = $( '<tr class="symbol" onclick="expandDesc(this)"></tr>' );
        row.append( $('<td class="left">' + name + '</td>') );
        row.append( $('<td class="right">' + data[key]['desc'] + '</td>') );

        var details = $( '<td colspan="2"></td>' );
        if ( data[key]['usage'] ) {
            var list = $( '<ul class="usage"></ul>' );
            for ( i in data[key]['usage'] ) {
                var item = $( '<li>' + data[key]['usage'][i] + '</li>' );
                list.append( item );
            }
            details.append( list );
        }
        details.append( data[key]['details'] );

        var drow = $( '<tr class="symbol_details" style="display: none;"></tr>' );
        drow.append( details );

        table.append( row );
        table.append( drow );
    }

    return table;
}

function expandDesc( e ) {
    $(e).toggleClass( 'open' );
    $(e).next().toggle();
}

function openRole( role ) {
    $('#main_subnav').find('#roles').trigger( 'click' );
    $('#SN-roles').find('#' + role).trigger( 'click' );
    fixView();
}

function start_debugger() {
    stage_set_step(0);

    $('#stage_r').unbind( 'click' );
    $('#stage_b').unbind( 'click' );
    $('#stage_f').unbind( 'click' );
    $('#stage_e').unbind( 'click' );

    $('#stage_r').click( function() { stage_set_step(0) } );
    $('#stage_b').click( function() { stage_set_step(step - 1) } );
    $('#stage_f').click( function() { stage_set_step(step + 1) } );
    $('#stage_e').click( function() { stage_set_step(steps.length - 1) } );
}

steps = new Array(
    { line: 0,  out: 0,  proc: 'parent', i: "", s: "", b: "" },
    { line: 1,  out: 3,  proc: 'parent', i: "", s: "", b: "" },
    { line: 3,  out: 5,  proc: 'parent' },
    { line: 28, out: 6,  proc: 'parent',  i: '' },
    { line: 6,  out: 6,  proc: 'parent',  i: 0, s: '' },
    { line: 7,  out: 6,  proc: 'parent',  s: 0, b: '' },
    { line: 8,  out: 6,  proc: 'parent',  b: 100, i: 0 },
    { line: 10, out: 6,  proc: 'parent',  i: 1 },

    { line: 12, out: 6,  proc: 'child_1', s: 1, b: 100 },
    { line: 15, out: 6,  proc: 'child_1', b: 0 },
    { line: 18, out: 7,  proc: 'child_1' },
    { line: 19, out: 8,  proc: 'child_1' },
    { line: 20, out: 9,  proc: 'child_1', b: 0},
    { line: 21, out: 9,  proc: 'child_1', s: 1, i: 1, b: 5 },
    { line: 24, out: 10, proc: 'child_1', s: 0, i: 0, b: 5 },

    { line: 13, out: 10, proc: 'child_2', s: 2, b: 100 },
    { line: 15, out: 10, proc: 'child_2', b: 0 },
    { line: 18, out: 11, proc: 'child_2' },
    { line: 19, out: 12, proc: 'child_2' },
    { line: 20, out: 13, proc: 'child_2', b: 0 },
    { line: 21, out: 13, proc: 'child_2', s: 2, i: 1, b: 5 },
    { line: 24, out: 14, proc: 'child_2', s: 0, i: 0, b: 5 },

    { line: 25, out: 14, proc: 'parent' },
    { line: 29, out: 16, proc: 'parent' },
    { line: 0,  out: 17, proc: 'parent', i: 1, s: 0, b: 100 }
);

var step = 0;
var proc = 'parent';

function stage_set_step( num ) {
    // Sanity
    if ( num < 0 ) num = 0;
    if ( num >= steps.length ) num = steps.length - 1;

    step = num;
    var data = steps[step];
    console.log( data );

    // Hide children
    $( '#debugger tr' ).removeClass( 'active' );
    $( '#debugger tr.child' ).hide();
    // Show proc if not parent
    if ( data['proc'] != 'parent' ) {
        $( '#debugger tr.' + data['proc'] ).show();
    }
    if( data['line'] ) $( '#debugger tr.' + data['proc'] ).addClass( 'active' );

    // if proc changed, copy parent vals to proc
    if ( data['proc'] != proc ) {
        proc = data['proc'];
        if ( proc != 'parent' ) {
            var parent = $( '#debugger_state tr.parent'  );
            var child  = $( '#debugger_state tr.' + proc );
            child.find( 'td.vinit' ).text( parent.find( 'td.vinit' ).text()   );
            child.find( 'td.vstate' ).text( parent.find( 'td.vstate' ).text() );
            child.find( 'td.vbleed' ).text( parent.find( 'td.vbleed' ).text() );
        }
    }
    // Set vals
    var prow = $( '#debugger_state tr.' + proc );
    if ( 'i' in data ) prow.find( 'td.vinit'  ).text( data['i'] );
    if ( 's' in data ) prow.find( 'td.vstate' ).text( data['s'] );
    if ( 'b' in data ) prow.find( 'td.vbleed' ).text( data['b'] );

    // unhighlight lines
    $( 'td#debug_source div.syntaxhighlighter div.line' ).removeClass( 'debug_highlight' );

    // Highlight line
    $(
        'td#debug_source div.syntaxhighlighter div.line.number' + data['line']
    ).addClass( 'debug_highlight' );

    // Hide output
    $( 'td#debug_out div.syntaxhighlighter div.line' ).hide();

    // Display output up to 'out'
    for( var i = 1; i <= data['out']; i++ ) {
        $( 'td#debug_out div.syntaxhighlighter div.line.number' + i ).show();
    }
}

