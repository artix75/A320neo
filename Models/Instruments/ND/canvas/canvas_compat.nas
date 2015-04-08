var _MP_dbg_lvl = "info";
#var _MP_dbg_lvl = "alert";
#io.include('Nasal/canvas/MapStructure.nas');

var makedie = func(prefix) func(msg) globals.die(prefix~" "~msg);

var __die = makedie("MapStructure");

var _arg2valarray = func
{
    var ret = arg;
    while (    typeof(ret) == "vector"
           and size(ret) == 1 and typeof(ret[0]) == "vector" )
    ret = ret[0];
    return ret;
}

var assert_m = func(hash, member)
    if (!contains(hash, member))
        die("required field not found: '"~member~"'");
var assert_ms = func(hash, members...)
    foreach (var m; members)
        if (m != nil) assert_m(hash, m);

##
# Combine a specific hash with a default hash, e.g. for
# options/df_options and style/df_style in a SymbolLayer.
#
var default_hash = func(opt, df) {
    if (opt != nil and typeof(opt)=='hash') {
        if (df != nil and opt != df and !isa(opt, df)) {
            if (contains(opt, "parents"))
            opt.parents ~= [df];
            else
                opt.parents = [df];
        }
        return opt;
    } else return df;
}


var try_aux_method = func(obj, method_name) {
    var name = "<test%"~id(caller(0)[0])~">";
    call(compile("obj."~method_name~"()", name), nil, var err=[]); # try...
    #debug.dump(err);
    if (size(err)) # ... and either leave caght or rethrow
    if (err[1] != name)
        die(err[0]);
}

Group.setColor = func(r,g,b, excl = nil){
    var children = me.getChildren();
    foreach(var e; children){
        var do_skip = 0;
        if(excl != nil){
            foreach(var cl; excl){
                if(isa(e, cl)){
                    do_skip = 1;
                    continue;                 
                }
            }
        }
        if(!do_skip)
            e.setColor(r,g,b);
    }
}

Symbol._new = func(m) {
    #m.style = m.layer.style;
    #m.options = m.layer.options;
    if (m.controller != nil) {
        temp = m.controller.new(m,m.model);
        if (temp != nil)
            m.controller = temp;
    }
    else __die("Symbol._new(): default controller not found");
};

Symbol.del = func() {
    if (me.controller != nil)
        me.controller.del(me, me.model);
    try_aux_method(me.model, "del");
};

SymbolLayer.findsym = func(model, del=0) {
    forindex (var i; me.list) {
        var e = me.list[i];
        #print("List["~i~"]");
        #debug.dump(e);
        if (Symbol.Controller.equals(e.model, model)) {
            if (del) {
                # Remove this element from the list
                # TODO: maybe C function for this? extend pop() to accept index?
                var prev = subvec(me.list, 0, i);
                var next = subvec(me.list, i+1);
                me.list = prev~next;
                #return 1;
            }
            return e;
        }
    }
    return nil;
};

# to add support for additional ghosts, just append them to the vector below, possibly at runtime:
var supported_ghosts = ['positioned','Navaid','Fix','flightplan-leg','FGAirport'];
var is_positioned_ghost = func(obj) {
    var gt = ghosttype(obj);
    foreach(var ghost; supported_ghosts) {
        if (gt == ghost) return 1; # supported ghost was found
    }
    return 0; # not a known/supported ghost
};

Symbol.Controller.equals = func(l, r, p=nil) {
    if (l == r) return 1;
    if (p == nil) {
        var ret = Symbol.Controller.equals(l, r, l);
        if (ret != nil) return ret;
        if (contains(l, "parents")) {
            foreach (var p; l.parents) {
                var ret = Symbol.Controller.equals(l, r, p);
                if (ret != nil) return ret;
            }
        }
        die("Symbol.Controller: no suitable equals() found! Of type: "~typeof(l));
    } else {
        if (typeof(p) == 'ghost')
            if ( is_positioned_ghost(p) )
                return l.id == r.id;
            else
                die("Symbol.Controller: bad/unsupported ghost of type '"~ghosttype(l)~"' (see MapStructure.nas Symbol.Controller.getpos() to add new ghosts)");
        if (typeof(p) == 'hash'){
            # Somewhat arbitrary convention:
            #   * l.equals(r)         -- instance method, i.e. uses "me" and "arg[0]"
            #   * parent._equals(l,r) -- class method, i.e. uses "arg[0]" and "arg[1]"
            if (contains(p, "equals"))
            return l.equals(r);
        }
        if (contains(p, "_equals"))
        return p._equals(l,r);
    }
    return nil; # scio correctum est
};

canvas.LineSymbol = {
    parents:[Symbol],
    element_id: nil,
    needs_update: 1,
    # Static/singleton:
    makeinstance: func(name, hash) {
    if (!isa(hash, LineSymbol))
    die("LineSymbol: OOP error");
    return Symbol.add(name, hash);
},
    # For the instances returned from makeinstance:
    new: func(group, model, controller=nil) {
        if (me == nil) die("Need me reference for LineSymbol.new()");
        if (typeof(model) != 'vector') die("LineSymbol.new(): need a vector of points");
        var m = {
            parents: [me],
            group: group,
            #layer: layer,
            model: model,
            controller: controller == nil ? me.df_controller : controller,
            element: group.createChild(
            "path", me.element_id
            ),
        };
        append(m.parents, m.element);
        Symbol._new(m);

        m.init();
        return m;
    },
    # Non-static:
    draw: func() {
        if (!me.needs_update) return;
        #printlog(_MP_dbg_lvl, "redrawing a LineSymbol "~me.layer.type);
        me.element.reset();
        var cmds = [];
        var coords = [];
        var cmd = Path.VG_MOVE_TO;
        foreach (var m; me.model) {
            var (lat,lon) = me.controller.getpos(m);
            append(coords,"N"~lat);
            append(coords,"E"~lon);
            append(cmds,cmd); 
            cmd = Path.VG_LINE_TO;
        }
        me.element.setDataGeo(cmds, coords);
        me.element.update(); # this doesn't help with flickering, it seems
    },
    del: func() {
        printlog(_MP_dbg_lvl, "LineSymbol.del()");
        me.deinit();
        call(Symbol.del, nil, me);
        me.element.del();
    },
    # Default wrappers:
    init: func() me.draw(),
    deinit: func(),
    update: func() {
        if (me.controller != nil) {
            if (!me.controller.update(me, me.model)) return;
            elsif (!me.controller.isVisible(me.model)) {
                me.element.hide();
                return;
            }
        } else
            me.element.show();
        me.draw();
    },
}; # of LineSymbol

Path.addSegmentGeo = func(cmd, coords...)
{
    var coords = _arg2valarray(coords);
    var num_coords = me.num_coords[cmd];
    if( size(coords) != num_coords )
    debug.warn
    (
        "Invalid number of arguments (expected " ~ num_coords ~ ")"
    );
    else
    {
        me.setInt("cmd[" ~ (me._last_cmd += 1) ~ "]", cmd);
        for(var i = 0; i < num_coords; i += 1)
            me.set("coord-geo[" ~ (me._last_coord += 1) ~ "]", coords[i]);
    }

    return me;
}

Path.arcGeo = func(cmd, rx,ry,unk,lat,lon){
    if(cmd < 18 and cmd > 24){
        debug.warn("Invalid command " ~ cmd);
        return me;
    }
    else
    {
        me.setInt("cmd[" ~ (me._last_cmd += 1) ~ "]", cmd);
        #for(var i = 0; i < num_coords; i += 1)
        me.setDouble("coord[" ~ (me._last_coord += 1) ~ "]", rx);
        me.setDouble("coord[" ~ (me._last_coord += 1) ~ "]", ry);
        me.setDouble("coord[" ~ (me._last_coord += 1) ~ "]", unk);
        me.setDouble("coord-geo[N" ~ (me._last_coord += 1) ~ "]", lat);
        me.setDouble("coord-geo[E" ~ (me._last_coord += 1) ~ "]", lat);
    }

    return me;
}

SymbolLayer.onRemoved = func(model) {
    #print('onRemoved');
    #debug.dump(model);
    var sym = me.findsym(model, 1);
    if (sym == nil) die("model not found");
    #print(typeof(model.del));
    #call(func sym.del, nil, var err = []);
    sym.del();
    #print('ERR CHK');
    #debug.dump(err);
    # ignore errors
    # TODO: ignore only missing member del() errors? and only from the above line?
    # Note: die(err[0]) rethrows it; die(err[0]~"") does not.
}

Map.addLayer = func(factory, type_arg=nil, priority=nil){
    if(contains(me.layers, type_arg))
    print("addLayer() warning: overwriting existing layer:", type_arg);

    # print("addLayer():", type_arg);

    # Argument handling
    if (type_arg != nil)
        var type = factory.get(type_arg);
    else var type = factory;

    var the_layer = me.layers[type_arg]= type.new(me);
    the_layer.map = me;
    if (priority == nil)
        priority = type.df_priority;
    if (priority != nil)
        me.layers[type_arg].setInt("z-index", priority);
    return me;
}

Map.getLat = func me.get("ref-lat");
Map.getLon = func me.get("ref-lon");
Map.getHdg = func me.get("hdg");
Map.getAlt = func me.get("altitude");
Map.getRange = func me.get("range");
Map.getLatLon = func [me.get("ref-lat"), me.get("ref-lon")];
Map.getPosCoord = func {
    var (lat, lon) = (me.get("ref-lat"),
                      me.get("ref-lon"));
    var alt = me.get("altitude");
    if (lat == nil or lon == nil) {
        if (contains(me, "coord")) {
            debug.warn("canvas.Map: lost ref-lat and/or ref-lon source");
        }
        return nil;
    }
    if (!contains(me, "coord")) {
        me.coord = geo.Coord.new();
        var m = me;
        me.coord.update = func m.getPosCoord();
    }
    me.coord.set_latlon(lat,lon,alt or 0);
    return me.coord;
}

SymbolLayer.new = func(group, controller=nil) {
    var m = {
        parents: [me],
        map: group,
        group: group.createChild("group", me.id), # TODO: the id is not properly set, but would be useful for debugging purposes (VOR, FIXES, NDB etc)
        list: [],
    };
    m.searcher = geo.PositionedSearch.new(me.searchCmd, me.onAdded, me.onRemoved, m);
    # FIXME: hack to expose type of layer:
    if (caller(1)[1] == Map.addLayer) {
        var this_type = caller(1)[0].type_arg;
        if (this_type != nil)
            m.group.set("symbol-layer-type", this_type);
    }
    if (controller == nil)
        #controller = SymbolLayer.Controller.new(me.type, m);
        controller = me.df_controller;
    assert_m(controller, "parents");
    if (controller.parents[0] == SymbolLayer.Controller)
        controller = controller.new(m);
    assert_m(controller, "parents");
    assert_m(controller.parents[0], "parents");
    if (controller.parents[0].parents[0] != SymbolLayer.Controller)
        die("OOP error");
    m.controller = controller;
    m.update();
    return m;
};

canvas.SingleSymbolLayer = {
    parents: [SymbolLayer]
};

canvas.MultiSymbolLayer = {
    parents: [SymbolLayer]
};

canvas.NavaidSymbolLayer = {
    parents: [canvas.MultiSymbolLayer]
};


