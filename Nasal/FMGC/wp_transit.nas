var wp_transit = {
       init : func {
            me.UPDATE_INTERVAL = 0.1;
            me.loopid = 0;
            
            me.current_wp = 0;
            
            setprop("/flight-management/current-wp", me.current_wp);
                  
            me.reset();
    },
    	update : func {
		
		if ((getprop("/autopilot/route-manager/route/num") > 1) and (getprop("/fbw/flight-phase") == "Flight Mode") and (getprop("/flight-management/end-flight") != 1)) {
		
		me.current_wp = getprop("/flight-management/current-wp");
		
		var gps_accur = getprop(settings~ "gps-accur");
		
		var accuracy = 0; # In Degrees, smaller is better for cruise, lower accuracy ensures a smoother WP transition
		
		if (gps_accur == "HIGH")
			accuracy = 0.005;
		else
			accuracy = 0.02;
			
		var pos_lat = getprop("/position/latitude-deg");
		var pos_lon = getprop("/position/longitude-deg");
		
		var wp_tree = "/autopilot/route-manager/route/wp[" ~ me.current_wp ~ "]/";
		
		var target_lat = getprop(wp_tree~ "latitude-deg");
		var target_lon = getprop(wp_tree~ "longitude-deg");
		
		if (getprop("autopilot/route-manager/current-wp") > me.current_wp) {
		
			me.current_wp = getprop("/autopilot/route-manager/current-wp");
		
		}
		
		if (getprop("/autopilot/route-manager/active") == 0) {
		
			setprop("/autopilot/route-manager/input", "@ACTIVATE");
			
			setprop("/autopilot/route-manager/input", "@JUMP" ~ me.current_wp);

		}
		
		if ((math.abs(pos_lat - target_lat) <= accuracy) and (math.abs(pos_lon - target_lon) <= accuracy)) {
		
			me.current_wp += 1;
			
			var last_wp = getprop("/autopilot/route-manager/route/num") - 1;
		
			if ((getprop("/autopilot/route-manager/route/wp[" ~ me.current_wp ~ "]/id") != nil) and (getprop("/flight-management/procedures/star/active-star/name") != "------")) {
		
				if (me.current_wp == last_wp) {
				
					print("--------------------------");
					print("[FMGC] TRANSITION TO ARRIVAL: " ~ getprop("/flight-management/procedures/star/active-star/name"));
					print("[FMGC] STAR: " ~ getprop("/flight-management/procedures/star/active-star/name") ~ " > TARGET SET: " ~ getprop("/flight-management/procedures/star/active-star/wp/name"));
				
				} else {
		
					print("--------------------------");
					print("[FMGC] WP" ~ (me.current_wp - 1) ~ " Reached...");
					print("[FMGC] TARGET SET: " ~ getprop("/autopilot/route-manager/route/wp[" ~ me.current_wp ~ "]/id"));
					
				}
			
			} else {
			
				print("--------------------------");
				print("[FMGC] LAST WP REACHED");
				setprop("/flight-management/end-flight", 1);
			
			}
			
		}
		
		if (getprop("/autopilot/route-manager/current-wp") != me.current_wp) {
		
			setprop("/autopilot/route-manager/input", "@JUMP" ~ me.current_wp);
		
		}
		
		setprop("/flight-management/current-wp", me.current_wp);
		
		} else {
		
			setprop("/flight-management/current-wp", 0);
		
		}
			
	},
	
        reset : func {
            me.loopid += 1;
            me._loop_(me.loopid);
    },
        _loop_ : func(id) {
            id == me.loopid or return;
            me.update();
            settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
    }

};

setlistener("sim/signals/fdm-initialized", func
 {
 wp_transit.init();
 print("Waypoint Transition Manager Initialized");
 });
