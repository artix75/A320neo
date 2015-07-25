# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'HOLD';
var parents = [canvas.SymbolLayer.Controller];
var __self__ = caller(0)[0];

canvas.SymbolLayer.Controller.add(name, __self__);
canvas.SymbolLayer.add(name, {
    parents: [MultiSymbolLayer],
    type: name, # Symbol type
    df_controller: __self__, # controller to use by default -- this one
});
var new = func(layer) {
    var m = {
        parents: [__self__],
        layer: layer,
        #map: layer.map,
        listeners: [],
    };
    #debug.dump(layer.parents);
    layer.searcher._equals = func(a,b) a.id == b.id;
    #append(m.listeners, setlistener(layer.options.fplan_active, func m.layer.update() ));
    #m.addVisibilityListener();
 
    return m;
};

var del = func() {
    foreach (var l; me.listeners)
        removelistener(l);
};
 
var searchCmd = func {
    var results = [];
    var node = props.globals.getNode(me.layer.options.hold_node);
    var wp_id = node.getValue('wp');
    if(wp_id == nil or wp_id == '' or wp_id == '---'){
        return [];
    }
    var pointsNode = node.getNode('points');
    var pointNode = nil;
    var lat = nil;
    var lon = nil;
    if(pointsNode != nil)
        pointNode = pointsNode.getNode('point', 0);
    if (pointNode != nil){
        lat = pointNode.getValue('lat');
        lon = pointNode.getValue('lon');
    }
    if (pointNode != nil and lat != nil and lon != nil){
        var r = node.getValue('crs');
        var d = node.getValue('dist');
        var t = node.getValue('turn');
        var model = {
            parents: [geo.Coord],
            id: wp_id~r~d~t,
            pos: pointNode,
            type: 'pattern',
            latlon: func(){ 
                return [
                    lat,
                    lon
                ];
            },
            radial: r,
            dist: d,
            turn: t,
            equals: func(o){me.id == o.id and me.radial == o.radial}
        };
        append(results, model);
    } else {
        var wp_idx = node.getValue('wp_id');
        var fp = flightplan();
        var wp = fp.getWP(wp_idx);
        #print("HOLD AT "~wp.wp_lat~", "~wp.wp_lon);
        if(wp == nil or wp.id != wp_id)
            return [];
        var wp_lat = wp.wp_lat;
        var wp_lon = wp.wp_lon;
        var model = {
            parents: [geo.Coord],
            id: wp_id~'-'~wp_idx~'-inactive',
            pos: nil,
            type: 'hold_symbol',
            latlon: func(){ 
                return [
                    wp_lat,
                    wp_lon
                ];
            },
            radial: node.getValue('crs'),
            dist: node.getValue('dist'),
            turn: node.getValue('turn'),
            equals: func(o){me.id == o.id}
        };
        append(results, model);
    }
        
    return results;
}
