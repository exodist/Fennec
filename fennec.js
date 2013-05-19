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
    if ( !hash ) hash = '#about';
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
            var viewitem = $(
                '<div style="display: none">' + dd.html() + '</div>'
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
                    subnav.children().hide();
                    navitem.unbind( 'click' );
                    navitem.click( function() {
                        subnav.children().show();
                        navitem.unbind( 'click' );
                        navitem.click( normal_click );
                        fixView();
                    });
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

    container.find( 'div.sub_list' ).each( function() {
        var list = $(this);
        jQuery.ajax(
            list.attr( 'src' ),
            {
                async: false,
                dataType: 'json',
                success: function( data ) {
                    list.detach();
                    build_sub_list( id, data );
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

    container.find( 'div.code' ).each( function() {
        var list = $(this);
        jQuery.ajax(
            list.attr( 'src' ),
            {
                dataType: 'text',
                success: function( data ) {
                    list.replaceWith( build_code( data ));
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

    container.find( 'div.output' ).each( function() {
        var list = $(this);
        jQuery.ajax(
            list.attr( 'src' ),
            {
                dataType: 'text',
                success: function( data ) {
                    list.replaceWith( build_output( data ));
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
}

function build_code( data ) {
    return '<div class="code">' + data + '</div>';
}

function build_output( data ) {
    return '<pre class="output">' + data + '</pre>';
}

function build_sub_list( pid, data ) {
    var subnav = $( '<ul id="SN-' + pid + '" style="display: none;" class="second_subnav listnav"></ul>' );

    var hash = window.location.hash;
    if ( !hash ) hash = '#about';
    var nav = hash.split('-');

    for (navkey in data) {
        build_sub_list_item( pid, navkey, data, nav, subnav );
    }

    $("#subnav").append( subnav );
}

function build_sub_list_item( pid, navkey, data, nav, subnav ) {
    var navname    = data[navkey]["name"];
    if ( !navname ) navname = navkey;
    var desc       = data[navkey]["desc"];
    var roles      = data[navkey]["roles"];
    var attributes = data[navkey]["attributes"];
    var methods    = data[navkey]["methods"];
    var requires   = data[navkey]["requires"];
    var keywords   = data[navkey]["keywords"];
    var functions  = data[navkey]["functions"];
    var operators  = data[navkey]["operators"];
    var sigils     = data[navkey]["sigils"];
    var types      = data[navkey]["types"];
    var usage      = data[navkey]["usage"];
    var father     = data[navkey]["parent"];

    var navitem = $(
        '<li id="' + navkey + '"><a href="' + nav[0] + '-' + pid + '-' + navkey + '">' + navname + '</a></li>'
    );
    var viewitem = $(
        '<div style="display: none"><h2>' + navname + '</h2>' + desc + '</div>'
    );

    if ( father ) {
        viewitem.append( '<h3>Lineage</h3>' );
        var list = $( '<ul class="lineage"></ul>' );
        var f = father;
        while ( f ) {
            list.append( '<li>' + f + '</li>' );
            if ( data[f] ) {
                f = data[f]["parent"];
                if (!f) f = "Object";
            }
            else {
                f = null;
            }
            if ( f == 'undef' ) break;
            if ( f ) list.append( '<li><b>&gt;</b></li>' );
        }
        viewitem.append( list );
    }

    if ( usage ) {
        viewitem.append( '<h3>Usage</h3>' );
        viewitem.append( usage );
    }

    if ( roles ) {
        viewitem.append( '<h3>Roles:</h3>' );
        var list = $('<ul class="role_list"></ul>');
        for (role in roles) {
            list.append( '<li><a href="' + nav[0] + '-roles-' + roles[role] + '" onclick="openRole(\'' + roles[role] + '\')">' + roles[role] + '<a></li>' );
        }
        viewitem.append( list );
    }

    if ( requires ) {
        viewitem.append( '<h3>Required Methods:</h3>' );
        viewitem.append( build_symbol_list( requires ));
    }

    if ( keywords ) {
        viewitem.append( '<h3>Keywords:</h3>' );
        viewitem.append( build_symbol_list( keywords ));
    }

    if ( functions ) {
        viewitem.append( '<h3>Functions:</h3>' );
        viewitem.append( build_symbol_list( functions ));
    }

    if ( types ) {
        viewitem.append( '<h3>Types:</h3>' );
        viewitem.append( build_symbol_list( types ));
    }

    if ( operators ) {
        viewitem.append( '<h3>Operators:</h3>' );
        viewitem.append( build_symbol_list( operators ));
    }

    if ( sigils ) {
        viewitem.append( '<h3>Sigils:</h3>' );
        viewitem.append( build_symbol_list( sigils ));
    }

    if ( attributes || roles ) {
        viewitem.append( '<h3>Attributes:</h3>' );
        var role_attributes = {};
        if ( roles ) {
            jQuery.ajax(
                'roles.json',
                {
                    async: false,
                    dataType: 'json',
                    success: function( data ) {
                        for ( var r in roles ) {
                            if (!data[roles[r]]) continue;

                            if ( data[roles[r]]['attributes'] ) {
                                role_attributes = $.extend( role_attributes, data[roles[r]]['attributes'] );
                            };
                        }
                    },
                    error: function() {
                        $( '#error_window' ).show();
                        $( '#error_window ul.errors' ).append( "<li>Error loading roles</li>" )
                    }
                }
            )
        }
        viewitem.append( build_symbol_list( $.extend( true, {}, role_attributes, attributes )));
    }

    if ( methods || roles ) {
        viewitem.append( '<h3>Methods:</h3>' );
        var role_methods = {};
        if ( roles ) {
            jQuery.ajax(
                'roles.json',
                {
                    async: false,
                    dataType: 'json',
                    success: function( data ) {
                        for ( var r in roles ) {
                            if (!data[roles[r]]) continue;

                            if ( data[roles[r]]['requires'] ) {
                                role_methods = $.extend( role_methods, data[roles[r]]['requires'] );
                            }
                            if ( data[roles[r]]['methods'] ) {
                                role_methods = $.extend( role_methods, data[roles[r]]['methods'] );
                            };
                        }
                    },
                    error: function() {
                        $( '#error_window' ).show();
                        $( '#error_window ul.errors' ).append( "<li>Error loading roles</li>" )
                    }
                }
            )
        }
        viewitem.append( build_symbol_list( $.extend( true, {}, role_methods, methods )));
    }

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
