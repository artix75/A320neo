var wp_transit = {
	init : func {
		me.UPDATE_INTERVAL = 0.1;
		me.loopid = 0;
		me.current_wp = 0;
		setprop("/flight-management/current-wp", me.current_wp);
		me.reset();
	},
	update : func {
		if(RouteManager.sequencing) return;
		var wp_count = getprop("/autopilot/route-manager/route/num");
		var fbw_phase = getprop("/fbw/flight-phase");
		var end_flight = getprop("/flight-management/end-flight");
		var cur_wp = getprop("/autopilot/route-manager/current-wp");
		if (wp_count > 1 and fbw_phase == "Flight Mode" and end_flight != 1 and 
			cur_wp != getprop("/flight-management/hold/hold-id")
			and cur_wp >= 0 and getprop("/flight-management/current-wp") >= 0) {
		
			me.current_wp = getprop("/flight-management/current-wp");
			var gps_accur = getprop(settings~ "gps-accur");
			var accuracy = 0; # In Degrees, smaller is better for cruise, lower accuracy ensures a smoother WP transition
			var fp_wp = fmgc_loop.wp;
			if(RouteManager.sequencing) fp_wp = nil;
			if(fp_wp != nil and fp_wp.fly_type == 'flyOver'){
				#if (gps_accur == "HIGH")
				#	accuracy = 0.0005;
				#else
				accuracy = 0.005;
			} else {
				#if (gps_accur == "HIGH")
				#	accuracy = 0.005;
				#else
				accuracy = 0.02;
				var leg_dist = getprop('/autopilot/route-manager/route/wp[' ~cur_wp~ ']/leg-distance-nm');
				if(cur_wp > 0 and cur_wp < (wp_count - 1) and leg_dist > 1){
					var nxt_wp = (cur_wp + 1);
					var bearing = getprop('/autopilot/route-manager/route/wp[' ~cur_wp~ ']/leg-bearing-true-deg');
					var bearing_next = getprop('/autopilot/route-manager/route/wp[' ~ nxt_wp ~ ']/leg-bearing-true-deg');
					var leg_dist_nxt = getprop('/autopilot/route-manager/route/wp[' ~nxt_wp~ ']/leg-distance-nm');
					var turn_deg = math.abs(utils.heading_diff_deg(bearing_next, bearing));
					var offset_nm = turn_deg * 0.03333333333333333;
					var spd_component = fmgc_loop.groundspeed / 200.0;
					if(spd_component > 1) offset_nm += spd_component;
					leg_dist -= 0.5;
					leg_dist_nxt -= 0.5;
					var shortest_dist = ((leg_dist_nxt < leg_dist) ? leg_dist_nxt : leg_dist);
					if(offset_nm > 1 and offset_nm > shortest_dist)
						offset_nm = shortest_dist;
					if(offset_nm < 1) offset_nm = 1;
					if(offset_nm > 5) offset_nm = 5;
					accuracy *= offset_nm;
				}
			}

			var pos_lat = getprop("/position/latitude-deg");
			var pos_lon = getprop("/position/longitude-deg");

			var wp_tree = "/autopilot/route-manager/route/wp[" ~ me.current_wp ~ "]/";

			var target_lat = getprop(wp_tree~ "latitude-deg");
			var target_lon = getprop(wp_tree~ "longitude-deg");

			if (cur_wp > me.current_wp)
				me.current_wp = cur_wp;

			if (getprop("/autopilot/route-manager/active") == 0) { #TODO: Why??
				setprop("/autopilot/route-manager/input", "@ACTIVATE");
				setprop("/autopilot/route-manager/input", "@JUMP" ~ me.current_wp);
				setprop("/autopilot/route-manager/active", 1);
			}

			if ((math.abs(pos_lat - target_lat) <= accuracy) and (math.abs(pos_lon - target_lon) <= accuracy)) {

				me.current_wp += 1;
				setprop("/flight-management/current-wp", me.current_wp);
				var dest_wp = RouteManager.getDestinationWP();
				var last_wp = (dest_wp != nil ? dest_wp.index : wp_count - 1);

				if (getprop("/autopilot/route-manager/route/wp[" ~ me.current_wp ~ "]/id") != nil) {

					if (me.current_wp == last_wp - 1) {

						print("--------------------------");
						var star_name = getprop("/flight-management/procedures/star/active-star/name");
						if (star_name != "------" and star_name != nil and star_name != 'DEFAULT') {
							print("[FMGC] TRANSITION TO ARRIVAL: " ~ star_name);
							print("[FMGC] STAR: " ~ star_name ~ " > TARGET SET: " ~ getprop("/flight-management/procedures/star/active-star/wp/name"));
						} else {

							print("[FMGC] ARRIVAL PROCEDURE NOT SET!");
							print("[FMGC] END OF F-PLN")

						}

					} else {

						print("--------------------------");
						print("[FMGC] WP" ~ (me.current_wp - 1) ~ " Reached...");
						print("[FMGC] TARGET SET: " ~ getprop("/autopilot/route-manager/route/wp[" ~ me.current_wp ~ "]/id"));
						setprop("/autopilot/route-manager/active", 1);

					}

				} else {

					print("--------------------------");
					print("[FMGC] LAST WP REACHED");
					setprop("/flight-management/end-flight", 1);

				}

			}
			if (cur_wp != me.current_wp)
				setprop("/autopilot/route-manager/input", "@JUMP" ~ me.current_wp);
			setprop("/flight-management/current-wp", me.current_wp);
		
		} else {
			setprop("/flight-management/current-wp", cur_wp);
		}
			
	},
	reset : func {
		me.loopid += 1;
		me._loop_(me.loopid);
	},
	_loop_ : func(id) {
		id == me.loopid or return;
		utils.catch(func me.update());
		settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
	}
};

setlistener("sim/signals/fdm-initialized", func
 {
 wp_transit.init();
 print("Waypoint Transition Manager Initialized");
 });
