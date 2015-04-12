var gps = "/instrumentation/gps/";

var dep = "/flight-management/procedures/sid/";

var f_pln_disp = "/instrumentation/mcdu/f-pln/disp/";

var DEGREES_TO_RADIANS = math.pi / 180;

var FEET_TO_METER = 0.3048;
var NM_TO_METER = 1852;

setprop(dep~ "active-sid/name", "------");

var sid = {

	select_arpt : func(icao) {
		
		me.DepICAO = procedures.fmsDB.new(icao);
		me.icao = icao;
		
		# Get a list of all available runways on the departure airport
		
		var info = airportinfo(icao);
		if (info == nil){
			setprop(dep~ "runway", '');
			me.update_rwys();
			return;
		}

		var runways = keys(info.runways);
		var rwy_count = size(runways);

		for(var rwy_index = 0; rwy_index < rwy_count; rwy_index += 1) {
			var rwy_name = runways[rwy_index];
			var rwy = info.runways[rwy_name];

			setprop(dep~ "runway[" ~ rwy_index ~ "]/id", rwy.id);

			setprop(dep~ "runway[" ~ rwy_index ~ "]/crs", int(rwy.heading));

			setprop(dep~ "runway[" ~ rwy_index ~ "]/length-m", int(rwy.length));

			setprop(dep~ "runway[" ~ rwy_index ~ "]/width-ft", rwy.width * globals.M2FT);

			var ils = rwy.ils;
			if (ils != nil){
				var ils_frq = ils.frequency;
				if(ils_frq == nil) ils_frq = 0; 
				ils_frq = ils_frq / 100;
				setprop(dep~ "runway[" ~ rwy_index ~ "]/ils-frequency-mhz", ils_frq);
			} else {
				setprop(dep~ "runway[" ~ rwy_index ~ "]/ils-frequency-mhz", 0);
			}

		}
		
		setprop(dep~ "runways", rwy_index);
		
		setprop("/instrumentation/mcdu/page", "RWY_SEL");
		
		setprop(dep~ "first", 0);
		
		setprop(dep~ "selected-rwy", "---");
		
		setprop(dep~ "selected-sid", "-------");
		
		me.update_rwys();
	
	},
	
	select_rwy : func(id) {
		
		if(me.DepICAO != nil){
			me.SIDList = me.DepICAO.getSIDList(id);
		} else {
			var defaultTp = procedures.fmsTP.new();
			defaultTp.tp_type = 'sid';
			defaultTp.wp_name = 'DEFAULT';
			defaultTp.runways = [id];
			me.SIDList = [defaultTp];
		}

		me.SIDmax = size(me.SIDList);
		
		for(var sid_index = 0; sid_index < me.SIDmax; sid_index += 1) {
		
			setprop(dep~ "sid[" ~ sid_index ~ "]/id", me.SIDList[sid_index].wp_name);
		
		}
		
		setprop(dep~ "selected-rwy", id);
		
		setprop(dep~ "sids", me.SIDmax);
		
		setprop("/instrumentation/mcdu/page", "SID_SEL");
		
		setprop(dep~ "first", 0);
		
		#setprop("/autopilot/route-manager/departure/runway", id);
		var arpt = airportinfo(me.icao);
		var rwy = arpt.runways[id];
		if(rwy == nil) return;
		var fp = f_pln.revise_flightplan();#f_pln.get_current_flightplan();
		fp.departure_runway = rwy;
		f_pln.update_flightplan_waypoints();
		
		me.update_sids();

		#var fp = flightplan();
		var sz = fp.getPlanSize();
		for(var i = 0; i < sz; i += 1){
			var wp = fp.getWP(i);
			if(wp.wp_role == 'sid' and wp.wp_type != 'runway'){
				fp.deleteWP(i);
				sz = fp.getPlanSize();
				i -= 1;
			}
		}
	
	},
	
	select_sid : func(n) {
	
		setprop(dep~ "selected-sid", me.SIDList[n].wp_name);
		
		setprop("/instrumentation/mcdu/page", "SID_CONFIRM");
		
		setprop(dep~ "sid-index", n);
	
	},
	
	confirm_sid : func(n) {
		var fp = mcdu.f_pln.get_current_flightplan();
		me.WPmax = size(me.SIDList[n].wpts);
		var skipped = 0;
		var do_trigger = 0;
		var wp_max = me.WPmax;
		var enroute_wp = nil;
		if(wp_max > 0){
			var last_wp = me.SIDList[n].wpts[wp_max - 1];
			enroute_wp = fmgc.RouteManager.findWaypointByID(last_wp.wp_name, fp.id);
			if(enroute_wp != nil){
				wp_max -= 1;
				fmgc.RouteManager.deleteWaypoints(1, enroute_wp.index - 1, fp.id);
			}
		}
		var last_wp_idx = 0;
		for(var wp = 0; wp < wp_max; wp += 1) {
		
			# Copy waypoints to property tree
			var sid_wp = me.SIDList[n].wpts[wp];
			
			setprop(dep~ "active-sid/wp[" ~ wp ~ "]/name", sid_wp.wp_name);
			
			setprop(dep~ "active-sid/wp[" ~ wp ~ "]/latitude-deg", sid_wp.wp_lat);
			
			setprop(dep~ "active-sid/wp[" ~ wp ~ "]/longitude-deg", sid_wp.wp_lon);
			
			setprop(dep~ "active-sid/wp[" ~ wp ~ "]/alt_cstr", sid_wp.alt_cstr);
			
			# Insert waypoints into Route Manager After Departure (INDEX = 0)
			
			#	setprop("/autopilot/route-manager/input", "@INSERT" ~ (wp + 1) ~ ":" ~ sid_wp.wp_lon ~ "," ~ sid_wp.wp_lat ~ "@" ~ sid_wp.alt_cstr);
			var wp_idx = (wp + 1) - skipped;
			var wpt = mcdu.f_pln.insert_procedure_wp('sid', sid_wp, wp_idx);
			if(wpt == nil) skipped += 1;
			last_wp_idx = wp_idx;
		}
		var is_default = 0;
		if (me.SIDList[n].wp_name == 'DEFAULT'){
			var current_fp = getprop(f_pln_disp~ "current-flightplan");
			if(current_fp != 'current' and current_fp != '' and current_fp != nil){
				var dpt = fp.departure;
				var dst = fp.destination;
				var rwy = dpt.runways[getprop(dep~ "selected-rwy")];
				if(dpt != nil and rwy != nil){
					var enroute_course = -1.0;
					if(dst != nil){
						var c1 = geo.Coord.new();
						var c2 = geo.Coord.new();
						c1.set_latlon(dpt.lat, dpt.lon);
						c2.set_latlon(dst.lat, dst.lon);
						enroute_course = c1.course_to(c2);
					}
					var idx = 1;
					var wpts = me.create_default_sid(dpt, rwy, enroute_course);
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
				setprop('/autopilot/route-manager/departure/sid', 'DEFAULT'); 
				setprop(dep~ "active-sid/name", 'DEFAULT');
			}
			is_default = 1;
		} else {
			setprop(dep~ "active-sid/name", me.SIDList[n].wp_name);
		}
		
		
		setprop("/flight-management/procedures/sid-current", 0);
		setprop("/flight-management/procedures/sid-transit", me.WPmax);
		
		var fp = f_pln.get_current_flightplan();
		var fpID = f_pln.get_flightplan_id();
		var wp = fp.getWP(0);
		if(fmgc.RouteManager.hasDiscontinuity(wp.id, fpID)){
			fmgc.RouteManager.clearDiscontinuity(wp.id, fpID);
			do_trigger = 1;
		}
		if(enroute_wp == nil and !is_default and last_wp_idx){
			var last_sid_wp = fp.getWP(last_wp_idx);
			if(last_sid_wp != nil){
				fmgc.RouteManager.setDiscontinuity(last_sid_wp.id, fpID);
				do_trigger = 1;
			}
		}
		if(do_trigger) 
			fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
		
		setprop("/instrumentation/mcdu/page", "f-pln");
		
		mcdu.f_pln.update_disp();
	
	},
	
	# The below functions will be to update mCDU display pages based on DEPARTURE
	
	update_rwys : func() {
	
		var first = getprop(dep~ "first"); # FIRST RWY
		
		for(var l = 0; l <= 3; l += 1) {
		
			if ((first + l) < getprop(dep~ "runways")) {
		
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/id", getprop(dep~ "runway[" ~ (first + l) ~ "]/id"));
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/crs", getprop(dep~ "runway[" ~ (first + l) ~ "]/crs"));
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/length-m", getprop(dep~ "runway[" ~ (first + l) ~ "]/length-m"));
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/width-ft", getprop(dep~ "runway[" ~ (first + l) ~ "]/width-ft"));
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/ils-frequency-mhz", getprop(dep~ "runway[" ~ (first + l) ~ "]/ils-frequency-mhz"));
				
			} else {
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/id", "---");
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/crs", "---");
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/length-m", "----");
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/width-ft", "");
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/ils-frequency-mhz", "");
			
			}
		
		}
	
	},
	
	update_sids: func() {
	
		var first = getprop(dep~ "first"); # FIRST SID
		
		for(var l = 0; l <= 3; l += 1) {
		
			if ((first + l) < getprop(dep~ "sids")) {
		
				setprop(dep~ "sid-disp/line[" ~ l ~ "]/id", getprop(dep~ "sid[" ~ (first + l) ~ "]/id"));
				
			} else {
			
				setprop(dep~ "sid-disp/line[" ~ l ~ "]/id", "------");
			
			}
		
		}
	
	},
	
	create_default_sid: func(arpt, rwy, aEnrouteCourse){
		if(rwy == nil) return nil;
		var rwy_len = rwy.length;
		var thresholdElevFt = arpt.elevation;
		
		var wp_id = rwy.id ~ '-3';
		var wpts = [];
		var coord = geo.Coord.new();
		coord.set_latlon(rwy.lat, rwy.lon);
		coord.apply_course_distance(rwy.heading, rwy_len + (3 * NM_TO_METER));
		var pos = {
			lat: coord.lat(),
			lon: coord.lon()
		};
		var wpt = createWP(pos, wp_id, 'sid');
		append(wpts, [wpt, thresholdElevFt + 3000]);
		
		wp_id = rwy.id ~ '-6';
		coord = geo.Coord.new();
		coord.set_latlon(rwy.lat, rwy.lon);
		coord.apply_course_distance(rwy.heading, rwy_len + (6 * NM_TO_METER));
		var pos = {
			lat: coord.lat(),
			lon: coord.lon()
		};
		wpt = createWP(pos, wp_id, 'sid');
		append(wpts, [wpt, thresholdElevFt + 6000]);
		
		if (aEnrouteCourse >= 0.0) {
			# valid enroute course
			var index = 3;
			var course = rwy.heading;
			var diff = 0.0;
			while (math.abs((diff = utils.heading_diff_deg(course, aEnrouteCourse))) > 45.0) {
				# turn in the sign of the heading change 45 degrees
				course += copysign(45.0, diff);

				wp_id = "DEP-" ~ index;
				index += 1;
				var last = wpts[size(wpts) - 1][0];
				var coord = geo.Coord.new();
				coord.set_latlon(last.wp_lat, last.wp_lon);
				coord.apply_course_distance(course, 3.0 * NM_TO_METER);
				var pos = {
					lat: coord.lat(),
					lon: coord.lon()
				};
				var wpt = createWP(pos, wp_id, 'sid');
				append(wpts, [wpt, 0]);
			}
		} else {
			wp_id = rwy.id ~ '-9';
			coord = geo.Coord.new();
			coord.set_latlon(rwy.lat, rwy.lon);
			coord.apply_course_distance(rwy.heading, rwy_len + (9 * NM_TO_METER));
			var pos = {
				lat: coord.lat(),
				lon: coord.lon()
			};
			wpt = createWP(pos, wp_id, 'sid');
			append(wpts, [wpt, thresholdElevFt + 9000]);
		}
		return wpts;
	}

};
