###################################
# Holding Pattern (Plot method)   #
# Author: Narendran Muraleedharan #
###################################

var NM2M = 1852;

var hold_pattern = {

	init: func() {
	
		setprop("/flight-management/hold/init", 1);
		
		print("[FMGC] Holding Pattern Initialized at " ~ getprop("/flight-management/hold/wp"));
		
		var radial = getprop("/flight-management/hold/crs");
		
		var turn = getprop("/flight-management/hold/turn");
		
		# Time isn't required as the dist is automatically calculated when time is entered
		
		var dist = getprop("/flight-management/hold/dist");
		
		var wp = getprop("/flight-management/hold/wp");
		
		# Get Position from GPS
		
		#setprop("/instrumentation/gps/scratch/query", wp);
		 			
		#if (size(wp) <= 3)
		#	setprop("/instrumentation/gps/scratch/type", "vor");
		#else
		#	setprop("/instrumentation/gps/scratch/type", "fix");
		#	
		#setprop("/instrumentation/gps/command", "search");
        var wp_id = getprop("/flight-management/hold/wp_id");
        var fp = flightplan();
        var fpWP = fp.getWP(wp_id);
		
		var pos_lat = fpWP.wp_lat;#getprop("/instrumentation/gps/scratch/latitude-deg");
		
        var pos_lon = fpWP.wp_lon;#getprop("/instrumentation/gps/scratch/longitude-deg");
		
		var wp_pos = geo.Coord.new();
		
		wp_pos.set_latlon(pos_lat, pos_lon);
		
		setprop("/flight-management/hold/points/point[0]/lat", pos_lat);
		setprop("/flight-management/hold/points/point[0]/lon", pos_lon);
		
		var rad_perp1 = 0;
        var ctrl_rad = 0;
		
		if (turn == "R") {
		
			if (radial + 90 > 360)
				rad_perp1 = radial - 270;
			else
				rad_perp1 = radial + 90;
            
            if (radial + 30 > 360)
                ctrl_rad = radial - 330;
            else
                ctrl_rad = radial + 30;
				
		} else {
		
			if (radial + 270 > 360)
				rad_perp1 = radial - 90;
			else
				rad_perp1 = radial + 270;
            
            if (radial + 330 > 360)
                ctrl_rad = radial - 30;
            else
                ctrl_rad = radial + 330;
		
		}
		
		wp_pos.apply_course_distance(rad_perp1, (dist * 2 * NM2M) / math.pi);
        
		setprop("/flight-management/hold/points/point[1]/lat", wp_pos.lat());
		setprop("/flight-management/hold/points/point[1]/lon", wp_pos.lon());
        
		var rad_inv = 0;
		
		if (radial + 180 > 360)
			rad_inv = radial - 180;
		else
			rad_inv = radial + 180;
		
		wp_pos.apply_course_distance(rad_inv, dist * NM2M);
		
		setprop("/flight-management/hold/points/point[2]/lat", wp_pos.lat());
		setprop("/flight-management/hold/points/point[2]/lon", wp_pos.lon());
		
		var rad_perp2 = 0;
		
		if (turn == "R") {
		
			if (radial + 270 > 360)
				rad_perp2 = radial - 90;
			else
				rad_perp2 = radial + 270;
				
		} else {
		
			if (radial + 90 > 360)
				rad_perp2 = radial - 270;
			else
				rad_perp2 = radial + 90;
		
		}
			
		wp_pos.apply_course_distance(rad_perp2, (dist * 2 * NM2M) / math.pi);
		
		setprop("/flight-management/hold/points/point[3]/lat", wp_pos.lat());
		setprop("/flight-management/hold/points/point[3]/lon", wp_pos.lon());
		
		# Determine the type of Entry
		
		var brg = getprop("/instrumentation/gps/scratch/mag-bearing-deg");
		
		setprop("/flight-management/hold/fly/course", brg);
		
		var diff1 = radial - brg;
		var diff2 = brg - radial;
		
		if (diff1 <= 0)
			diff1 = 360 - math.abs(diff1);
		if (diff2 <= 0)
			diff2 = 360 - math.abs(diff2);
		
		if ((diff1 <= 110) or (diff2 <= 70)) {
		
			setprop("/flight-management/hold/entry", "direct");
		
		} elsif ((diff1 > 110) and (diff2 <= 180)) {
			
			setprop("/flight-management/hold/entry", "tear-drop");
			
			setprop("/flight-management/hold/entry-phase", 0);
		
		} else {
		
			setprop("/flight-management/hold/entry", "parallel");
			
			setprop("/flight-management/hold/entry-phase", 0);
		
		}
		
		setprop("/flight-management/hold/phase", 5);
		
	
	},
	
	entry: func() {
	
		var ac = geo.aircraft_position();
	
		if (getprop("/flight-management/hold/entry") == "direct") {
			
			setprop("/flight-management/hold/phase", 0);
			
		} elsif (getprop("/flight-management/hold/entry") == "parallel") {
		
			var entry_phase = getprop("/flight-management/hold/entry-phase");
			
			if (entry_phase == 0) {
			
				if ((math.abs(ac.lat() - me.point_lat(0)) < 0.016) and (math.abs(ac.lon() - me.point_lon(0)) < 0.016)) {
				
					setprop("/flight-management/hold/entry-phase", 1);
				
				} else {
				
					me.flyto(me.point_lat(0), me.point_lon(0));
				
				}
			
			} else {
			
				if ((math.abs(ac.lat() - me.point_lat(3)) < 0.016) and (math.abs(ac.lon() - me.point_lon(3)) < 0.016)) {
				
					setprop("/flight-management/hold/phase", 0);
				
				} else {
				
					me.flyto(me.point_lat(3), me.point_lon(3));
				
				}
			
			}
		
		} else {
		
			var entry_phase = getprop("/flight-management/hold/entry-phase");
			
			if (entry_phase == 0) {
			
				if ((math.abs(ac.lat() - me.point_lat(2)) < 0.016) and (math.abs(ac.lon() - me.point_lon(2)) < 0.016)) {
				
					setprop("/flight-management/hold/entry-phase", 1);
				
				} else {
				
					me.flyto(me.point_lat(2), me.point_lon(2));
				
				}
			
			} elsif (entry_phase == 1) {
			
				if ((math.abs(ac.lat() - me.point_lat(3)) < 0.016) and (math.abs(ac.lon() - me.point_lon(3)) < 0.016)) {
				
					setprop("/flight-management/hold/phase", 0);
				
				} else {
				
					me.flyto(me.point_lat(3), me.point_lon(3));
				
				}
			
			}
		
		}
	
	},
	
	transit: func() {
	
		var ac = geo.aircraft_position();
	
		var phase = getprop("/flight-management/hold/phase");
		
		if ((math.abs(ac.lat() - me.point_lat(phase)) < 0.016) and (math.abs(ac.lon() - me.point_lon(phase)) < 0.016)) {
				
					if (phase < 3)
						setprop("/flight-management/hold/phase", phase + 1);
					else
						setprop("/flight-management/hold/phase", 0);
				
				} else {
				
					me.flyto(me.point_lat(phase), me.point_lon(phase));
				
				}
	
	},
	
	flyto: func(lat, lon) {
	
		var pos = geo.Coord.new();
		
		pos.set_latlon(lat, lon);
		
		var ac = geo.aircraft_position();
		
		setprop("/flight-management/hold/fly/course", ac.course_to(pos));
	
	},
	
	point_lat: func(index) {
	
		return getprop("/flight-management/hold/points/point[" ~ index ~ "]/lat");
	
	},
	
	point_lon: func(index) {
	
		return getprop("/flight-management/hold/points/point[" ~ index ~ "]/lon");
	
	}

};


