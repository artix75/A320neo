var procedure = {

	check : func() {
                if(getprop("/flight-management/procedures/sid/active-sid/name") == 'DEFAULT')
                    return 'off';
                if(getprop("/flight-management/procedures/iap/active-iap/name") == 'DEFAULT')
                    return 'off';
	
		var rte_len = getprop("/autopilot/route-manager/route/num");
	
		if ((getprop("/flight-management/procedures/sid/active-sid/name") != "------") and (getprop("/flight-management/current-wp") == 1) and (getprop("/flight-management/procedures/sid-current") != getprop("/flight-management/procedures/sid-transit")) and (getprop("/flight-management/control/lat-ctrl") == "fmgc")) { # Standard Departure
		
			return "sid";
		
		} elsif ((getprop("/flight-management/procedures/sid/active-star/name") != "------") and (getprop("/flight-management/current-wp") == (rte_len - 1)) and (getprop("/flight-management/procedures/star-current") != getprop("/flight-management/procedures/star-transit")) and (getprop("/flight-management/control/lat-ctrl") == "fmgc")) {
		
			return "star";
		
		} elsif ((getprop("/flight-management/procedures/iap/active-iap/name") != "------") and (getprop("/flight-management/procedures/star-current") == getprop("/flight-management/procedures/star-transit")) and (getprop("/flight-management/procedures/iap-current") != getprop("/flight-management/procedures/iap-transit")) and (getprop("/flight-management/control/lat-ctrl") == "fmgc")) { 

			return "iap";
		
		} else {
		
			return "off";
		
		}
	
	},
	
	reset_tp : func() {
	
		setprop("/flight-management/procedures/active", "off");
		
		setprop("/flight-management/procedures/sid-current", 0);
		
		setprop("/flight-management/procedures/star-current", 0);
		
		setprop("/flight-management/procedures/iap-current", 0);
	
	},
	
	fly_sid : func() {
	
		var current_wp = getprop("/flight-management/procedures/sid-current");
		
		var target_lat = getprop("/flight-management/procedures/sid/active-sid/wp[" ~ current_wp ~ "]/latitude-deg");
		
		var target_lon = getprop("/flight-management/procedures/sid/active-sid/wp[" ~ current_wp ~ "]/longitude-deg");
		
		if ((target_lat == 0) or (target_lon == 0)){
            setprop("/flight-management/procedures/sid-current", current_wp + 1);
            return;
        }
			
		#var current_wp = getprop("/flight-management/procedures/sid-current");
		
		setprop("/flight-management/procedures/sid/course", me.course_to(target_lat, target_lon));
		
		var pos_lat = getprop("/position/latitude-deg");
		
		var pos_lon = getprop("/position/longitude-deg");
		
		var accuracy = 0.02;
		
		if ((math.abs(pos_lat - target_lat) <= accuracy) and (math.abs(pos_lon - target_lon) <= accuracy)) {
		
			setprop("/flight-management/procedures/sid-current", current_wp + 1);
			
			var current_wp = getprop("/flight-management/procedures/sid-current");
			
			var transit_wp = getprop("/flight-management/procedures/sid-transit");
		
			if (current_wp < transit_wp) {
		
				print("--------------------------");
				print("[FMGC] SID: " ~ getprop("/flight-management/procedures/sid/active-sid/name") ~ " > WP" ~ (current_wp - 1) ~ " Reached...");
				print("[FMGC] SID: " ~ getprop("/flight-management/procedures/sid/active-sid/name") ~ " > TARGET SET: " ~ getprop("/flight-management/procedures/sid/active-sid/wp[" ~ current_wp ~ "]/name"));
			
			} else {
			
				print("--------------------------");
				print("[FMGC] TRANSITION TO F-PLN");
			
			}
			
		}
	
	},
	
	fly_star : func() {
	
		var current_wp = getprop("/flight-management/procedures/star-current");
		
		var target_lat = getprop("/flight-management/procedures/star/active-star/wp[" ~ current_wp ~ "]/latitude-deg");
		
		var target_lon = getprop("/flight-management/procedures/star/active-star/wp[" ~ current_wp ~ "]/longitude-deg");
		
		if ((target_lat == 0) or (target_lon == 0))
			setprop("/flight-management/procedures/star-current", current_wp + 1);
			
		var current_wp = getprop("/flight-management/procedures/star-current");
		
		setprop("/flight-management/procedures/star/course", me.course_to(target_lat, target_lon));
		
		var pos_lat = getprop("/position/latitude-deg");
		
		var pos_lon = getprop("/position/longitude-deg");
		
		var accuracy = 0.02;
		
		if ((math.abs(pos_lat - target_lat) <= accuracy) and (math.abs(pos_lon - target_lon) <= accuracy)) {
		
			setprop("/flight-management/procedures/star-current", current_wp + 1);
			
			var current_wp = getprop("/flight-management/procedures/star-current");
			
			var transit_wp = getprop("/flight-management/procedures/star-transit");
		
			if (current_wp < transit_wp) {
		
				print("--------------------------");
				print("[FMGC] STAR: " ~ getprop("/flight-management/procedures/star/active-star/name") ~ " > WP" ~ (current_wp - 1) ~ " Reached...");
				print("[FMGC] STAR: " ~ getprop("/flight-management/procedures/star/active-star/name") ~ " > TARGET SET: " ~ getprop("/flight-management/procedures/star/active-star/wp[" ~ current_wp ~ "]/name"));
			
			} else {
			
				print("--------------------------");
				print("[FMGC] TRANSITION TO APPROACH");
			
			}
			
		}
	
	},
	
	fly_iap : func() {
	
	var current_wp = getprop("/flight-management/procedures/iap-current");
		
		var target_lat = getprop("/flight-management/procedures/iap/active-iap/wp[" ~ current_wp ~ "]/latitude-deg");
		
		var target_lon = getprop("/flight-management/procedures/iap/active-iap/wp[" ~ current_wp ~ "]/longitude-deg");
		
		if ((target_lat == 0) or (target_lon == 0))
			setprop("/flight-management/procedures/iap-current", current_wp + 1);
			
		var current_wp = getprop("/flight-management/procedures/iap-current");
		
		setprop("/flight-management/procedures/iap/course", me.course_to(target_lat, target_lon));
		
		var pos_lat = getprop("/position/latitude-deg");
		
		var pos_lon = getprop("/position/longitude-deg");
		
		var accuracy = 0.02;
		
		if ((math.abs(pos_lat - target_lat) <= accuracy) and (math.abs(pos_lon - target_lon) <= accuracy)) {
		
			setprop("/flight-management/procedures/iap-current", current_wp + 1);
			
			var current_wp = getprop("/flight-management/procedures/iap-current");
			
			var transit_wp = getprop("/flight-management/procedures/iap-transit");
		
			if (current_wp < transit_wp) {
		
				print("--------------------------");
				print("[FMGC] IAP: " ~ getprop("/flight-management/procedures/iap/active-iap/name") ~ " > WP" ~ (current_wp - 1) ~ " Reached...");
				print("[FMGC] IAP: " ~ getprop("/flight-management/procedures/iap/active-iap/name") ~ " > TARGET SET: " ~ getprop("/flight-management/procedures/iap/active-iap/wp[" ~ current_wp ~ "]/name"));
			
			} else {
			
				print("--------------------------");
				print("[FMGC] ---------- END OF F-PLN ----------");
			
			}
			
		}
	
	},
	
	course_to : func(lat = 0,lon = 0) {
	
		var aircraft_pos = geo.aircraft_position();
	
		var wp_pos = geo.Coord.new();
		
		wp_pos.set_latlon(lat, lon);
		
		var course_to_wp = aircraft_pos.course_to(wp_pos);
		
		return course_to_wp;
	
	},

};
