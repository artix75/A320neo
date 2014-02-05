var gps = "/instrumentation/gps/";

var dep = "/flight-management/procedures/sid/";

setprop(dep~ "active-sid/name", "------");

var sid = {

	select_arpt : func(icao) {
		
		me.DepICAO = procedures.fmsDB.new(icao);
		
		# Get a list of all available runways on the departure airport
		
		setprop(gps~ "scratch/query", icao);
		setprop(gps~ "scratch/type", "airport");
		setprop(gps~ "command", "search");
		
		for(var rwy_index = 0; getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/id") != nil; rwy_index += 1) {
		
			setprop(dep~ "runway[" ~ rwy_index ~ "]/id", getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/id"));
			
			setprop(dep~ "runway[" ~ rwy_index ~ "]/crs", getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/heading-deg"));
			
			setprop(dep~ "runway[" ~ rwy_index ~ "]/length-m", getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/length-ft") * 0.3048);
			
			setprop(dep~ "runway[" ~ rwy_index ~ "]/width-ft", getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/width-ft"));
		
		}
		
		setprop(dep~ "runways", rwy_index);
		
		setprop("/instrumentation/mcdu/page", "RWY_SEL");
		
		setprop(dep~ "first", 0);
		
		setprop(dep~ "selected-rwy", "---");
		
		setprop(dep~ "selected-sid", "-------");
		
		me.update_rwys();
	
	},
	
	select_rwy : func(id) {
	
		me.SIDList = me.DepICAO.getSIDList(id);
		me.SIDmax = size(me.SIDList);
		
		for(var sid_index = 0; sid_index < me.SIDmax; sid_index += 1) {
		
			setprop(dep~ "sid[" ~ sid_index ~ "]/id", me.SIDList[sid_index].wp_name);
		
		}
		
		setprop(dep~ "selected-rwy", id);
		
		setprop(dep~ "sids", me.SIDmax);
		
		setprop("/instrumentation/mcdu/page", "SID_SEL");
		
		setprop(dep~ "first", 0);
		
		setprop("/autopilot/route-manager/departure/runway", id);
		
		me.update_sids();
	
	},
	
	select_sid : func(n) {
	
		setprop(dep~ "selected-sid", me.SIDList[n].wp_name);
		
		setprop("/instrumentation/mcdu/page", "SID_CONFIRM");
		
		setprop(dep~ "sid-index", n);
	
	},
	
	confirm_sid : func(n) {
	
		me.WPmax = size(me.SIDList[n].wpts);
		
		for(var wp = 0; wp < me.WPmax; wp += 1) {
		
			# Copy waypoints to property tree
		
			setprop(dep~ "active-sid/wp[" ~ wp ~ "]/name", me.SIDList[n].wpts[wp].wp_name);
			
			setprop(dep~ "active-sid/wp[" ~ wp ~ "]/latitude-deg", me.SIDList[n].wpts[wp].wp_lat);
			
			setprop(dep~ "active-sid/wp[" ~ wp ~ "]/longitude-deg", me.SIDList[n].wpts[wp].wp_lon);
			
			setprop(dep~ "active-sid/wp[" ~ wp ~ "]/alt_cstr", me.SIDList[n].wpts[wp].alt_cstr);
			
			# Insert waypoints into Route Manager After Departure (INDEX = 0)
			
			#	setprop("/autopilot/route-manager/input", "@INSERT" ~ (wp + 1) ~ ":" ~ me.SIDList[n].wpts[wp].wp_lon ~ "," ~ me.SIDList[n].wpts[wp].wp_lat ~ "@" ~ me.SIDList[n].wpts[wp].alt_cstr);
		
		}
		
		setprop(dep~ "active-sid/name", me.SIDList[n].wp_name);
		
		setprop("/flight-management/procedures/sid-current", 0);
		setprop("/flight-management/procedures/sid-transit", me.WPmax);
		
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
				
			} else {
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/id", "---");
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/crs", "---");
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/length-m", "----");
			
				setprop(dep~ "rwy-disp/line[" ~ l ~ "]/width-ft", "");
			
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
	
	}

};
