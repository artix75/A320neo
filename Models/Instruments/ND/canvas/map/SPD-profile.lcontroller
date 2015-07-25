# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'SPD-profile';
var parents = [canvas.SymbolLayer.Controller];
var __self__ = caller(0)[0];

var _options = { # default configuration options
    alts: [100,140,250,260,'wp']
};
canvas.SymbolLayer.Controller.add(name, __self__);
canvas.SymbolLayer.add(name, {
    parents: [MultiSymbolLayer],
    type: name, # Symbol type
    df_controller: __self__, # controller to use by default -- this one
    df_options: _options
});
var new = func(layer) {
    var m = {
        parents: [__self__],
        layer: layer,
        #map: layer.map,
        listeners: [],
    };
    layer.searcher._equals = func(a,b) a.getName() == b.getName();
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
    var symNode = props.globals.getNode(me.layer.options.spd_node);
    if (symNode != nil)
        foreach (var alt; me.layer.options.alts) {
            t = 'spd-change-point' ~ '-' ~ alt;
            #print('SPD-Controller, search for '~t);
            var n = symNode.getNode(t);
            if (n != nil and n.getValue('longitude-deg') != nil){
                #print('SPD-Controller -> Append');
                append(results, n);
            }
        }
    return results;
}
