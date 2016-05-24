var posToTower = func (){
    var i = airportinfo();
    var twr = i.tower();
    var lat = twr.lat;
    var lon = twr.lon;
    setprop('position/latitude-deg', lat);
    setprop('position/longitude-deg', lon);
    setprop('position/altitude-agl-ft', i.elevation);
}

var printTowerPos = func (){
    var i = airportinfo();
    var twr = i.tower();
    var lat = twr.lat;
    var lon = twr.lon;
    print("Tower position (" ~ i.id  ~ ")");
    print("Lat: " ~ lat);
    print("Lon: " ~ lon);
}

var clickSound = func(n){
    if (getprop("sim/freeze/replay-state"))
        return;
    var propName = "sim/sound/click"~n;
    setprop(propName,1);
    settimer(func { setprop(propName,0) },0.4);
}

var fastStartUp = func(){
    systems.startup();
    setprop('controls/flight/flaps',0.596);
    while (getprop("consumables/fuel/total-fuel-kg") < 30812) {
        setprop("/consumables/fuel/tank[1]/level-kg", getprop("/consumables/fuel/tank[1]/level-kg") + 5);
        setprop("/consumables/fuel/tank[2]/level-kg", getprop("/consumables/fuel/tank[2]/level-kg") + 20);
        setprop("/consumables/fuel/tank[3]/level-kg", getprop("/consumables/fuel/tank[3]/level-kg") + 35);
        setprop("/consumables/fuel/tank[4]/level-kg", getprop("/consumables/fuel/tank[4]/level-kg") + 20);
        setprop("/consumables/fuel/tank[5]/level-kg", getprop("/consumables/fuel/tank[5]/level-kg") + 5);
    }
    setprop('services/chokes/left', 0);
    setprop('services/chokes/right', 0);
    setprop('services/chokes/nose', 0);
    setprop('services/ext-pwr/enable', 0);
    setprop('/controls/gear/tiller-enabled', 1);
}

var flyApproach = func(dest_arpt, dest_rwy, dist = 20){
    var fmgct = "/flight-management/control/";
    var fcu = "/flight-management/fcu-values/";
    
    var apt = airportinfo(dest_arpt);
    if (apt == nil){
        print('Airport not found!');
        return;
    }
    var rwy = apt.runways[dest_rwy];
    if (rwy == nil){
        print('Runway not found!');
        return;
    }
    var rwy_ils = rwy.ils;
    var crs = num(dest_rwy) * 10;
    if (rwy_ils != nil){
        var radio = "/flight-management/freq/";
        var frq = rwy_ils.frequency / 100;
        var crs = rwy_ils.course;
        print ('Tuning NAV to ' ~ frq ~ 'mhz, crs: '~ crs);
        setprop(radio~ "ils", frq);
        setprop(radio~ "ils-crs", int(crs));
        setprop(radio~ "ils-mode", 1);
        mcdu.rad_nav.switch_nav1(1);
    }
    var alt = apt.elevation + (dist * 125);
    var spd = 250;
    var lat = -9999;
    var lng = -9999;
    var pos_on_flightplan = 0;
    var fp_active = getprop("/autopilot/route-manager/active");
    if (fp_active){
        var fp = flightplan();
        var wp_count = getprop("/autopilot/route-manager/route/num");
        var lastidx = wp_count - 1;
        var wp = nil;
        var i = 0;
        var tot_dist = getprop('/autopilot/route-manager/total-distance');
        var dist_offset = tot_dist - dist;
        for(var i = lastidx; i >= 0; i = i - 1){
            var wp = fp.getWP(i);
            var wp_dist = wp.distance_along_route;
            if (wp_dist < dist_offset) break;
        }
        if (wp != nil){
            var id = wp.id;
            print("T.O. Waypoint: "~ id);
            var point = fp.pathGeod(-1, -dist);
            lat = point.lat;
            lng = point.lon;
            dest_arpt = '';
            dest_rwy = '';
            crs = getprop('/autopilot/route-manager/route/wp['~i~']/leg-bearing-true-deg');
            setprop("/autopilot/route-manager/input", "@JUMP" ~ i);
            setprop("/flight-management/current-wp", i);
            pos_on_flightplan = 1;
        }
    }
    setprop('controls/flight/flaps',0);
    setlistener("sim/signals/fdm-initialized", func{
        settimer(func(){
            setprop(fcu~ 'alt', alt);
            setprop(fcu~ 'hdg', crs);
            setprop(fcu~ 'ias', spd);
            setprop(fmgct~ 'lat-ctrl', 'man-set');
            setprop(fmgct~ 'ver-ctrl', 'man-set');
            setprop(fmgct~ 'ver-mode', 'alt');
            setprop(fmgct~ 'spd-mode', 'ias');
            setprop(fmgct~ 'spd-ctrl', 'man-set');
            setprop(fmgct~ "a-thrust", "eng");
            setprop(fmgct~ "ap1-master", "eng");
        },5);
    });
    setprop('/sim/presets/airport-id', dest_arpt);
    setprop('/sim/presets/runway', dest_rwy);
    setprop("/sim/presets/longitude-deg", lng);
    setprop("/sim/presets/latitude-deg", lat);
    if (pos_on_flightplan){
        setprop('/sim/presets/heading-deg', crs);
    } else {
        setprop('/sim/presets/offset-distance-nm', dist);
    }
    setprop('/sim/presets/altitude-ft', alt + 300);
    setprop('/sim/presets/airspeed-kt', spd);
    fgcommand('reposition');
}

var test_nd_symbol = func(symbol, dist_nm){
    var prop = "autopilot/route-manager/vnav/"~symbol;
    var node = props.globals.getNode(prop);
    if(dist_nm == 0){
        if(node != nil)
            node.remove();
    } else {
        if (getprop("/autopilot/route-manager/active")){
            var f= flightplan(); 
            var point = f.pathGeod(0, dist_nm);
            setprop(prop ~ "/latitude-deg", point.lat); 
            setprop(prop ~ "/longitude-deg", point.lon);
        } 
    }
    var rt = 'autopilot/route-manager/route/';
    var n = getprop(rt~'num');
    if(n != nil and n != 0){
        var bearing = 0;
        var idx = 0;
        for(idx = 0; idx < n; idx += 1){
            var wp = rt~'wp['~idx~']';
            var dist = getprop(wp~'/distance-along-route-nm');
            if(dist >= dist_nm){
                break;
            }
            bearing = getprop(wp~'/leg-bearing-true-deg');
        }
        setprop(prop~'/bearing-deg', bearing);
    }

    setprop('instrumentation/efis/nd/current-'~symbol, dist_nm);
}

var print_flightplan = func(fpId = nil){
    fp = fmgc.RouteManager.getFlightPlan(fpId);
    if(fp == nil){
        print('No flightplan named '~ fpId);
        return;
    }
    var n = getprop('autopilot/route-manager/route/num');
    var last_bearing = 0;
    for(i = 0; i < n; i = i + 1){
        var wp = fp.getWP(i);
        var bearing = wp.leg_bearing;
        print('ID: ' ~ wp.id);
        print('Index: '~ wp.index);
        print('Name: ' ~ wp.wp_name);
        print('Type: ' ~ wp.wp_type);
        print('Role: ' ~ (wp.wp_role != nil ? wp.wp_role : 'nil'));
        print('Lat: ' ~ wp.wp_lat);
        print('Lon: ' ~ wp.wp_lon);
        print('Parent: ' ~ (wp.wp_parent != nil ? wp.wp_parent : 'nil'));
        print('Fly Type: ' ~ wp.fly_type);
        print('Alt CSTR: ' ~ wp.alt_cstr);
        print('Alt CSTR Type: ' ~ (wp.alt_cstr_type != nil ? wp.alt_cstr_type : 'nil'));
        print('Spd CSTR: ' ~ wp.speed_cstr);
        print('Spd CSTR Type: ' ~ (wp.speed_cstr_type != nil ? wp.speed_cstr_type : 'nil'));
        print('Leg distance: ' ~ wp.leg_distance);
        print('Leg bearing: ' ~ bearing);
        if(i > 0){
            var bearing_diff = heading_diff_deg(bearing, last_bearing);
            print('Turn deg: ' ~ bearing_diff);
        }
        print('Dist along rte: ' ~ wp.distance_along_route);
        print('-------------------------');
        print('');
        last_bearing = bearing;
    }
}

var reload_sound = func(){
    fgcommand("reinit", props.Node.new({ subsystem: "sound" }));
}

var normalize_range = func( val, min, max ) {
	var step = max - min;
	while( val >= max )  val -= step;
	while( val < min ) val += step;
	return val;
};

var heading_diff_deg = func(a, b){
	var rawDiff = b - a;
	return normalize_range(rawDiff, -180.0, 180.0);
}

var reload_nasal = func(path, namespace){
	var ac_dir = getprop('sim/aircraft-dir');
	io.load_nasal(ac_dir~ '/' ~ path, namespace);
}

var catch = func(fn){
	var res = call(fn, nil, var e = []);
	if(size(e)){
		debug.printerror(e);
		print("You have encountered a bug in the A320neo model.");
		print("Please, report it along with the above message and description of what you");
		print("were doing when it happened to https://github.com/FGMEMBERS/A320neo/issues");
		var prop = "/warnings/simulator-bug-count";
		setprop(prop, (getprop(prop) or 0) + 1);
	}
	return res;
}

