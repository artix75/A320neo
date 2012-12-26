var gps = "/instrumentation/gps/";

var arr = "/flight-management/procedures/star/";

var iap = "/flight-management/procedures/iap/";

setprop(arr~ "active-star/name", "------");

var star = {

	select_arpt : func(icao) {
		
		me.ArrICAO = procedures.fmsDB.new(icao);
		
		# Get a list of all available runways on the departure airport
		
		setprop(gps~ "scratch/query", icao);
		setprop(gps~ "scratch/type", "airport");
		setprop(gps~ "command", "search");
		
		for(var rwy_index = 0; getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/id") != nil; rwy_index += 1) {
		
			setprop(arr~ "runway[" ~ rwy_index ~ "]/id", getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/id"));
			
			setprop(arr~ "runway[" ~ rwy_index ~ "]/crs", getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/heading-deg"));
			
			setprop(arr~ "runway[" ~ rwy_index ~ "]/length-m", getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/length-ft") * 0.3048);
			
			setprop(arr~ "runway[" ~ rwy_index ~ "]/width-ft", getprop(gps~ "scratch/runways[" ~ rwy_index ~ "]/width-ft"));
		
		}
		
		setprop(arr~ "runways", rwy_index);
		
		setprop("/instrumentation/mcdu/page", "ARR_RWY_SEL");
		
		setprop(arr~ "first", 0);
		
		setprop(arr~ "selected-rwy", "---");
		
		setprop(arr~ "selected-star", "-------");
		
		me.update_rwys();
	
	},
	
	select_rwy : func(id) {
	
		me.STARList = me.ArrICAO.getSTARList(id);
		me.STARmax = size(me.STARList);
		
		me.ApproachList = me.ArrICAO.getApproachList(id);
		
		for(var star_index = 0; star_index < me.STARmax; star_index += 1) {
		
			setprop(arr~ "star[" ~ star_index ~ "]/id", me.STARList[star_index].wp_name);
		
		}
		
		setprop(arr~ "selected-rwy", id);
		
		setprop(arr~ "stars", me.STARmax);
		
		setprop("/instrumentation/mcdu/page", "STAR_SEL");
		
		setprop(arr~ "first", 0);
		
		setprop("/autopilot/route-manager/destination/runway", id);
		
		me.update_stars();
		
		me.confirm_iap(id);
	
	},
	
	select_star : func(n) {
	
		setprop(arr~ "selected-star", me.STARList[n].wp_name);
		
		setprop("/instrumentation/mcdu/page", "STAR_CONFIRM");
		
		setprop(arr~ "star-index", n);
	
	},
	
	confirm_star : func(n) {
	
		me.WPmax = size(me.STARList[n].wpts);
		
		for(var wp = 0; wp < me.WPmax; wp += 1) {
		
			# Copy waypoints to property tree
		
			setprop(arr~ "active-star/wp[" ~ wp ~ "]/name", me.STARList[n].wpts[wp].wp_name);
			
			setprop(arr~ "active-star/wp[" ~ wp ~ "]/latitude-deg", me.STARList[n].wpts[wp].wp_lat);
			
			setprop(arr~ "active-star/wp[" ~ wp ~ "]/longitude-deg", me.STARList[n].wpts[wp].wp_lon);
			
			setprop(arr~ "active-star/wp[" ~ wp ~ "]/alt_cstr", me.STARList[n].wpts[wp].alt_cstr);
			
		}
		
		setprop(arr~ "active-star/name", me.STARList[n].wp_name);
		
		setprop("/flight-management/procedures/star-current", 0);
		setprop("/flight-management/procedures/star-transit", me.WPmax);
		
		setprop("/instrumentation/mcdu/page", "f-pln");
		
		mcdu.f_pln.update_disp();
	
	},
	
	confirm_iap : func(id) {
	
		setprop(iap~ "selected-iap", me.ApproachList[0].wp_name);
	
		me.WPmax = size(me.ApproachList[0].wpts);
		
		setprop(iap~ "iap-index", 0);
		
		for(var wp = 0; wp < me.WPmax; wp += 1) {
		
			# Copy waypoints to property tree
		
			setprop(iap~ "active-iap/wp[" ~ wp ~ "]/name", me.ApproachList[0].wpts[wp].wp_name);
			
			setprop(iap~ "active-iap/wp[" ~ wp ~ "]/latitude-deg", me.ApproachList[0].wpts[wp].wp_lat);
			
			setprop(iap~ "active-iap/wp[" ~ wp ~ "]/longitude-deg", me.ApproachList[0].wpts[wp].wp_lon);
			
			setprop(iap~ "active-iap/wp[" ~ wp ~ "]/alt_cstr", me.ApproachList[0].wpts[wp].alt_cstr);
			
		}
		
		setprop(iap~ "active-iap/name", me.ApproachList[0].wp_name);
		
		setprop("/flight-management/procedures/iap-current", 0);
		setprop("/flight-management/procedures/iap-transit", me.WPmax);
		
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
				
			} else {
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/id", "---");
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/crs", "---");
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/length-m", "----");
			
				setprop(arr~ "rwy-disp/line[" ~ l ~ "]/width-ft", "");
			
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
	
	}

};
