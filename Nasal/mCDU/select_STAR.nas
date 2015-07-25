var gps = "/instrumentation/gps/";

var arr = "/flight-management/procedures/star/";

var iap = "/flight-management/procedures/iap/";

var f_pln_disp = "/instrumentation/mcdu/f-pln/disp/";

setprop(arr~ "active-star/name", "------");

var DEGREES_TO_RADIANS = math.pi / 180;

var FEET_TO_METER = 0.3048;
var NM_TO_METER = 1852;

var copysign = func (x, y){
	if ((x < 0 and y > 0) or (x > 0 and y < 0))
		return -x;
	return x;
};

var star = {

	select_arpt : func(icao) {
		
		me.ArrICAO = procedures.fmsDB.new(icao);
		me.icao = icao;
		
		# Get a list of all available runways on the departure airport

		var info = airportinfo(icao);
		if (info == nil){
			setprop(arr~ "runway", '');
			me.update_rwys();
			return;
		}

		var runways = keys(info.runways);
		var rwy_count = size(runways);
		
		for(var rwy_index = 0; rwy_index < rwy_count; rwy_index += 1) {
			var rwy_name = runways[rwy_index];
			var rwy = info.runways[rwy_name];

			setprop(arr~ "runway[" ~ rwy_index ~ "]/id", rwy.id);

			setprop(arr~ "runway[" ~ rwy_index ~ "]/crs", int(rwy.heading));

			setprop(arr~ "runway[" ~ rwy_index ~ "]/length-m", int(rwy.length));

			setprop(arr~ "runway[" ~ rwy_index ~ "]/width-ft", rwy.width * globals.M2FT);

			var ils = rwy.ils;
			if (ils != nil){
				var ils_frq = ils.frequency;
				if(ils_frq == nil) ils_frq = 0; 
				ils_frq = ils_frq / 100;
				setprop(arr~ "runway[" ~ rwy_index ~ "]/ils-frequency-mhz", ils_frq);
			} else {
				setprop(arr~ "runway[" ~ rwy_index ~ "]/ils-frequency-mhz", 0);
			}

		}
		
		setprop(arr~ "runways", rwy_index);
		
		setprop("/instrumentation/mcdu/page", "ARR_RWY_SEL");
		
		setprop(arr~ "first", 0);
		
		setprop(arr~ "selected-rwy", "---");
		
		setprop(arr~ "selected-star", "-------");
		
		me.update_rwys();
	
	},
	
	select_rwy : func(id) {
	
		if(me.ArrICAO != nil){
			me.STARList = me.ArrICAO.getSTARList(id);
			me.ApproachList = me.ArrICAO.getApproachList(id);
		}else {
			var defaultTp = procedures.fmsTP.new();
			defaultTp.tp_type = 'star';
			defaultTp.wp_name = 'DEFAULT';
			defaultTp.runways = [id];
			me.STARList = [defaultTp];
			me.ApproachList = [];
		}
		me.STARmax = size(me.STARList);
		
		for(var star_index = 0; star_index < me.STARmax; star_index += 1) {
		
			setprop(arr~ "star[" ~ star_index ~ "]/id", 
					me.STARList[star_index].wp_name);
		
		}
		
		setprop(arr~ "selected-rwy", id);
		
		setprop(arr~ "stars", me.STARmax);
		
		setprop("/instrumentation/mcdu/page", "STAR_SEL");
		
		setprop(arr~ "first", 0);
		var arpt = airportinfo(me.icao);
		var rwy = arpt.runways[id];
		if(rwy == nil) return;
		var fp = f_pln.revise_flightplan();#f_pln.get_current_flightplan();
		#setprop("/autopilot/route-manager/destination/runway", id);
		fp.destination_runway = rwy;
		f_pln.update_flightplan_waypoints();
		
		me.update_stars();
		
		var sz = fp.getPlanSize();
		for(var i = 0; i < sz; i += 1){
			var wp = fp.getWP(i);
			var type = wp.wp_type;
			var role = wp.wp_role;
			if((role == 'star' or role == 'approach' or role == 'missed') and 
			    type != 'runway'){
				fp.deleteWP(i);
				i -= 1;
				sz = fp.getPlanSize();
			}
		}
		
		fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
		
		#me.confirm_iap(id);
	
	},
	
	select_star : func(n) {
	
		setprop(arr~ "selected-star", me.STARList[n].wp_name);
		
		setprop("/instrumentation/mcdu/page", "STAR_CONFIRM");
		
		setprop(arr~ "star-index", n);
	
	},
	
	confirm_star : func(n) {
		var fp = mcdu.f_pln.get_current_flightplan();
		me.WPmax = size(me.STARList[n].wpts);
		var skipped = 0;
		var wp_offs = 0;
		var dest_wpt = mcdu.f_pln.get_destination_wp();
		var last_idx = dest_wpt.index;
		var enroute_wp = nil;
		var last_enroute_wp = (last_idx > 1 ? fp.getWP(last_idx - 1) : nil);
		if(me.WPmax > 0){
			var first_wp = me.STARList[n].wpts[0];
			enroute_wp = fmgc.RouteManager.findWaypointByID(first_wp.wp_name, fp.id);
			if(enroute_wp != nil){
				wp_offs = 1;
				var enroute_idx = enroute_wp.index;
				if(last_enroute_wp != nil and enroute_idx <= last_enroute_wp.index)
					last_enroute_wp = nil;
				var len = last_idx - enroute_idx;
				fmgc.RouteManager.deleteWaypoints(enroute_idx, len, fp.id);
				dest_wpt = mcdu.f_pln.get_destination_wp();
				last_idx = dest_wpt.index;
			}
		}

		for(var wp = wp_offs; wp < me.WPmax; wp += 1) {
			var star_wp = me.STARList[n].wpts[wp];
			# Copy waypoints to property tree
		
			setprop(arr~ "active-star/wp[" ~ wp ~ "]/name", star_wp.wp_name);
			
			setprop(arr~ "active-star/wp[" ~ wp ~ "]/latitude-deg", star_wp.wp_lat);
			
			setprop(arr~ "active-star/wp[" ~ wp ~ "]/longitude-deg", star_wp.wp_lon);
			
			setprop(arr~ "active-star/wp[" ~ wp ~ "]/alt_cstr", star_wp.alt_cstr);
			
			var wp_idx = (wp + last_idx) - skipped;
			var wpt = mcdu.f_pln.insert_procedure_wp('star', star_wp, wp_idx);
			if(wpt == nil) skipped += 1;
			
		}
		
		setprop(arr~ "active-star/name", me.STARList[n].wp_name);
		
		setprop("/flight-management/procedures/star-current", 0);
		setprop("/flight-management/procedures/star-transit", me.WPmax);
		
		setprop("/instrumentation/mcdu/page", "f-pln");
		var do_trigger = 0;
		var is_default = 0;
		#var fp = f_pln.get_current_flightplan();
		var fpID = f_pln.get_flightplan_id();
		if(me.STARList[n].wp_name == 'DEFAULT'){
			is_default = 1;
			var current_fp = getprop(f_pln_disp~ "current-flightplan");
			if(current_fp != 'current' and current_fp != '' and current_fp != nil){
				var fp = mcdu.f_pln.get_current_flightplan();
				var dep = fp.departure;
				var dst = fp.destination;
				var rwy = dst.runways[getprop(arr~ "selected-rwy")];
				if(dst != nil and rwy != nil){
					var enroute_course = -1.0;
					if(dep != nil){
						var c1 = geo.Coord.new();
						var c2 = geo.Coord.new();
						c1.set_latlon(dep.lat, dep.lon);
						c2.set_latlon(dst.lat, dst.lon);
						enroute_course = c1.course_to(c2);
					}
					var wpts = me.create_default_approach(dst, rwy, enroute_course);
					var dst_wp = mcdu.f_pln.get_destination_wp();
					var idx = dst_wp.index;
					foreach(var wp_info; wpts){
						var wp = wp_info[0];
						var alt = 0;
						if(size(wp_info) > 1)
							alt = wp_info[1];
						fp.insertWP(wp, idx);
						if(alt > 0){
							wp = fp.getWP(idx);
							wp.setAltitude(alt, 'at');
						}
						idx += 1;
					}
				}
				do_trigger = 1;
			} else {
				setprop('/autopilot/route-manager/destination/approach', 'DEFAULT');
				setprop(arr~ "active-star/name", 'DEFAULT');
				setprop(iap~ "active-iap/name", 'DEFAULT');
			}
		} else {
			var rwy = getprop(arr~ "selected-rwy");
			me.confirm_iap(rwy);
		}
		if(last_enroute_wp != nil and is_default){
			if(fmgc.RouteManager.hasDiscontinuity(last_enroute_wp.id, fpID)){
				fmgc.RouteManager.clearDiscontinuity(last_enroute_wp.id, fpID);
				do_trigger = 1;
			}
		}
		elsif(enroute_wp == nil and !is_default and last_enroute_wp != nil){
			fmgc.RouteManager.setDiscontinuity(last_enroute_wp.id, fpID);
			do_trigger = 1;
		}
		if(do_trigger) 
			fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
		mcdu.f_pln.update_disp();
	
	},
	
	confirm_iap : func(id) {
		#print('Confirming IAP, number of Approaches: ', size(me.ApproachList) );
		if(size(me.ApproachList) == 0) return;
	
		setprop(iap~ "selected-iap", me.ApproachList[0].wp_name);
	
		me.WPmax = size(me.ApproachList[0].wpts);
		
		setprop(iap~ "iap-index", 0);
		
		var skipped = 0;
		var dest_wpt = mcdu.f_pln.get_destination_wp();
		var last_idx = dest_wpt.index;
		var type = 'approach';
		
		for(var wp = 0; wp < me.WPmax; wp += 1) {
		
			# Copy waypoints to property tree
			var appr_wp = me.ApproachList[0].wpts[wp];
		
			setprop(iap~ "active-iap/wp[" ~ wp ~ "]/name", appr_wp.wp_name);
			
			setprop(iap~ "active-iap/wp[" ~ wp ~ "]/latitude-deg", appr_wp.wp_lat);
			
			setprop(iap~ "active-iap/wp[" ~ wp ~ "]/longitude-deg", appr_wp.wp_lon);
			
			setprop(iap~ "active-iap/wp[" ~ wp ~ "]/alt_cstr", appr_wp.alt_cstr);
			
			if(string.trim(appr_wp.real_type) == 'Runway' and type != 'missed'){
				type = 'missed';
				skipped += 1;
				last_idx += 1;
				continue;
			}
			var wp_idx = (wp + last_idx) - skipped;
			var wpt = mcdu.f_pln.insert_procedure_wp(type, appr_wp, wp_idx);
			if(wpt == nil) skipped += 1;
		}
		
		setprop(iap~ "active-iap/name", me.ApproachList[0].wp_name);
		
		setprop("/flight-management/procedures/iap-current", 0);
		setprop("/flight-management/procedures/iap-transit", me.WPmax);
		fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
		
	},
	
	# The below functions will be to update mCDU display pages based on DEPARTURE
	
	update_rwys : func() {
	
		var first = getprop(arr~ "first"); # FIRST RWY
		
		for(var l = 0; l <= 3; l += 1) {
		
			if ((first + l) < getprop(arr~ "runways")) {
		
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/id", getprop(arr~ "runway[" ~ (first + l) ~ "]/id"));
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/crs", getprop(arr~ "runway[" ~ (first + l) ~ "]/crs"));
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/length-m", getprop(arr~ "runway[" ~ (first + l) ~ "]/length-m"));
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/width-ft", getprop(arr~ "runway[" ~ (first + l) ~ "]/width-ft"));
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/ils-frequency-mhz", getprop(arr~ "runway[" ~ (first + l) ~ "]/ils-frequency-mhz"));
				
			} else {
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/id", "---");
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/crs", "---");
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/length-m", "----");
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/width-ft", "");
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/ils-frequency-mhz", "");
			
			}
		
		}
	
	},
	
	update_stars: func() {
	
		var first = getprop(arr~ "first"); # FIRST star
		
		for(var l = 0; l <= 3; l += 1) {
		
			if ((first + l) < getprop(arr~ "stars")) {
		
				setprop(arr~ "star-disp/line[" ~ l ~ "]/id", getprop(arr~ "star[" ~ (first + l) ~ "]/id"));
				
			} else {
			
				setprop(arr~ "star-disp/line[" ~ l ~ "]/id", "------");
			
			}
		
		}
	
	},
	
	create_default_approach: func(arpt, rwy, aEnrouteCourse){
		if(rwy == nil) return nil;
		var thresholdElevFt = arpt.elevation;
		var approachHeightFt = 2000.0;
		var glideslopeDistanceM = (approachHeightFt * FEET_TO_METER) /
			math.tan(3.0 * DEGREES_TO_RADIANS);
		var wp_id = rwy.id ~ '-12';
		var wpts = [];
		var coord = geo.Coord.new();
		coord.set_latlon(rwy.lat, rwy.lon);
		coord.apply_course_distance(rwy.heading, -12 * NM_TO_METER);
		var pos = {
			lat: coord.lat(),
			lon: coord.lon()
		};
		var wpt = createWP(pos, wp_id, 'approach');
		append(wpts, [wpt, thresholdElevFt + 4000]);
		if (aEnrouteCourse >= 0.0) {
			# valid enroute course
			var index = 4;
			var course = rwy.heading;
			var diff = 0.0;
			while (math.abs((diff = utils.heading_diff_deg(aEnrouteCourse, course))) > 45.0) {
				# turn in the sign of the heading change 45 degrees
				course -= copysign(45.0, diff);
				
				wp_id = "APP-" ~ index;
				index += 1;
				var first = wpts[0][0];
				var coord = geo.Coord.new();
				coord.set_latlon(first.wp_lat, first.wp_lon);
				coord.apply_course_distance(course + 180.0, 3.0 * NM_TO_METER);
				var pos = {
					lat: coord.lat(),
					lon: coord.lon()
				};
				var wpt = createWP(pos, wp_id, 'approach');
				wpts = [[wpt, 0]] ~ wpts;
			}
		}
		coord = geo.Coord.new();
		coord.set_latlon(rwy.lat, rwy.lon);
		coord.apply_course_distance(rwy.heading, -8 * NM_TO_METER);
		pos = {
			lat: coord.lat(),
			lon: coord.lon()
		};
		wp_id = rwy.id ~ '-8';
		wpt = createWP(pos, wp_id, 'approach');
		append(wpts, [wpt, thresholdElevFt + approachHeightFt]);
		
		coord = geo.Coord.new();
		coord.set_latlon(rwy.lat, rwy.lon);
		coord.apply_course_distance(rwy.heading, -glideslopeDistanceM);
		pos = {
			lat: coord.lat(),
			lon: coord.lon()
		};
		wp_id = rwy.id ~ '-GS';
		wpt = createWP(pos, wp_id, 'approach');
		append(wpts, [wpt, thresholdElevFt + approachHeightFt]);
		return wpts;
	}

};
