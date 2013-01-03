# LAT and VER REV pages are managed separately

var rm_route = "/autopilot/route-manager/";

var f_pln_disp = "/instrumentation/mcdu/f-pln/disp/";

var f_pln = {

	init_f_pln : func {
	
		# Completely Clear Route Manager, add the new waypoints from 'active_rte' and then add the departure and arrival icaos.
		
		# NOTE: Flightplans are only (re-)initialized when switched between active and secondary, and re-initialized after SID (- F-PLN DISCONTINUITY -)
		
		## RESET Terminal Procedure Manager
		
		fmgc.procedure.reset_tp();
		
		## Deactivate Route Manager
		
		setprop(rm_route~ "active", 0);
		
		## Clear the Route Manager
		
		setprop(rm_route~ "input", "@CLEAR");
		
		## Remove Departure and Destination
		
		setprop(rm_route~ "departure/airport", "");
		setprop(rm_route~ "destination/airport", "");
		setprop(rm_route~ "departure/runway", "");
		setprop(rm_route~ "destination/runway", "");
		
		## Copy Waypoints and altitudes from active-rte
		
		for (var index = 0; getprop(active_rte~ "route/wp[" ~ index ~ "]/wp-id") != nil; index += 1) {
		
			var wp_id = getprop(active_rte~ "route/wp[" ~ index ~ "]/wp-id");
			
			var wp_alt = getprop(active_rte~ "route/wp[" ~ index ~ "]/altitude-ft");
		
			if (wp_alt == nil)
				wp_alt = 10000;
		
			setprop(rm_route~ "input", "@INSERT99:" ~ wp_id ~ "@" ~ wp_alt);
		
		}
		
		# Copy Speeds to Route Manager Property Tree
		
		var max_wp = getprop(rm_route~ "route/num");
		
		for (var wp = 0; wp < max_wp; wp += 1) {
		
			var wp_spd = getprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach");
			
			if (wp_spd != nil)
				setprop(rm_route~ "route/wp[" ~ wp ~ "]/ias-mach", wp_spd);
		
		}
		
		## Reset Departure and Destination from active RTE
		
		var dep = getprop(active_rte~ "depicao");
		
		var arr = getprop(active_rte~ "arricao");
		
		setprop(rm_route~ "departure/airport", dep);
		setprop(rm_route~ "destination/airport", arr);
		
		if(getprop("/flight-management/alternate/icao") == "empty") {
		
			setprop(rm_route~ "input", "@INSERT99:" ~ dep ~ "@0");
		
		} else {
		
			setprop(rm_route~ "input", "@INSERT99:" ~ getprop("/flight-management/alternate/icao") ~ "@0");
		
		}
		
		## Calculate Times to each WP starting with FROM at 0000 and using determined speeds
		
		setprop(rm_route~ "route/wp/leg-time", 0);
		
		for (var wp = 1; wp < getprop(rm_route~ "route/num"); wp += 1) {
		
			var dist = getprop(rm_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-distance-nm");
			
			var spd = getprop(rm_route~ "route/wp[" ~ wp ~ "]/ias-mach");
			
			var alt = getprop(rm_route~ "route/wp[" ~ wp ~ "]/altitude-ft");
			
			var gs_min = 0; # Ground Speed in NM/min
			
			if ((spd == nil) or (spd == 0)) {
			
				# Use 250 kts if under FL100 and 0.78 mach if over FL100
				
				if (alt <= 10000)
					spd = 250;
				else
					spd = 0.78;
			
			}		
			
			# MACH SPEED
			
			if (spd < 1) {
			
				gs_min = 10 * spd;
			
			}
			
			# AIRSPEED
			
			else {
			
				gs_min = spd + (alt / 200);
			
			}
			
			# Time in Minutes (rounded)
			
			var time_min = int(dist / gs_min);
			
			var last_time = 0;
			
			if (wp != 1)
				last_time = getprop(rm_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-time");
			else
				last_time = getprop(rm_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-time") + 30;
				
			# Atm, using 30 min for taxi time. You will be able to change this in INIT B when it's completed
			
			var total_time = last_time + time_min;
			
			setprop(rm_route~ "route/wp[" ~ wp ~ "]/leg-time", total_time);
		
		}
		
		me.update_disp();
		
		setprop("/autopilot/route-manager/current-wp", 0);
	
	},
	
	cpy_to_active : func {
	
		for (var wp = 0; getprop(rm_route~ "route/wp[" ~ wp ~ "]/id") != nil; wp += 1) {
		
			setprop(active_rte~ "route/wp[" ~ wp ~ "]/wp-id", getprop(rm_route~ "route/wp[" ~ wp ~ "]/id"));
			
			var alt = getprop(rm_route~ "route/wp[" ~ wp ~ "]/altitude-ft");
			
			var spd = getprop(rm_route~ "route/wp[" ~ wp ~ "]/ias-mach");
			
			if (alt != nil)
				setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", alt);
				
			if (spd != nil)
				setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", spd);
				
		
		}
		
		setprop("/instrumentation/mcdu/input", "MSG: F-PLN SAVED TO ACTIVE RTE");
	
	},
	
	update_disp : func {
	
		# This function is simply to update the display in the Active Flight Plan Page. This gets first wp ID and then places the others accordingly.
		
		# - F-PLN DISCONTINUITY - is showed when first wp id = dep and - END OF F-PLN - is showed when wps in l1 to l4 are the last.
		
		var first = getprop(f_pln_disp~ "first");
		
		# Calculate times
		
		for (var wp = 1; wp < getprop(rm_route~ "route/num"); wp += 1) {
		
			var dist = getprop(rm_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-distance-nm");
			
			var spd = getprop(rm_route~ "route/wp[" ~ wp ~ "]/ias-mach");
			
			var alt = getprop(rm_route~ "route/wp[" ~ wp ~ "]/altitude-ft");
			
			var gs_min = 0; # Ground Speed in NM/min
			
			if ((spd == nil) or (spd == 0)) {
			
				# Use 250 kts if under FL100 and 0.78 mach if over FL100
				
				if (alt <= 10000)
					spd = 250;
				else
					spd = 0.78;
			
			}		
			
			# MACH SPEED
			
			if (spd < 1) {
			
				gs_min = 10 * spd;
			
			}
			
			# AIRSPEED
			
			else {
			
				gs_min = spd + (alt / 200);
			
			}
			
			# Time in Minutes (rounded)
			
			var time_min = int(dist / gs_min);
			
			var last_time = 0;
			
			if (wp != 1)
				last_time = getprop(rm_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-time");
			else
				last_time = getprop(rm_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-time") + 30;
				
			# Atm, using 30 min for taxi time. You will be able to change this in INIT B when it's completed
			
			var total_time = last_time + time_min;
			
			setprop(rm_route~ "route/wp[" ~ wp ~ "]/leg-time", total_time);
		
		}
		
		# Destination details --------------------------------------------------
		
		var num = getprop(rm_route~ "route/num");
		
		if (num >= 2) {
		
			var dest_id = num - 1;
		
			var dest_name = getprop(rm_route~ "route/wp[" ~ dest_id ~ "]/id");
		
			var dest_time = getprop(rm_route~ "route/wp[" ~ dest_id ~ "]/leg-time");

			var dest_time_str = "";
		
			if (dest_time != nil) {
			
				if (dest_time < 10)
					dest_time_str = "000" ~ int(dest_time);
				elsif (dest_time < 100)
					dest_time_str = "00" ~ int(dest_time);
				elsif (dest_time < 1000)
					dest_time_str = "0" ~ int(dest_time);
				else
					dest_time_str = int(dest_time);
			
			} else {
			
				dest_time_str = "----";
			
			}
		
			# Set Airborne to get distance to last waypoint
		
			setprop(rm_route~ "active", 1);
		
			setprop(rm_route~ "airborne", 1);
		
			var rte_dist = getprop(rm_route~ "wp-last/dist");
		
			setprop(rm_route~ "active", 0);
	
			setprop(f_pln_disp~ "dest", dest_name);
		
			setprop(f_pln_disp~ "time", dest_time_str);
		
			if (rte_dist != nil)
				setprop(f_pln_disp~ "dist", int(rte_dist));
			else
				setprop(f_pln_disp~ "dist", "----");
			
		} else {
		
			setprop(f_pln_disp~ "dest", "----");
			
			setprop(f_pln_disp~ "time", "----");
			
			setprop(f_pln_disp~ "dist", "----");
		
		}
		
		# PAGE 1 ---------------------------------------------------------------
		
		if (first == 0) {
		
			# L1 DEPARTURE -----------------------------------------------------
			
			var dep = getprop(rm_route~ "route/wp/id");
			
			if (dep != nil) {
			
			var time_dep = "0000";
			
			var spd_alt = "---/-----";
			
			setprop(f_pln_disp~ "l1/id", dep);
			
			setprop(f_pln_disp~ "l1/time", time_dep);
			
			setprop(f_pln_disp~ "l1/spd_alt", spd_alt);
			
			}
			
			# L2 is empty (- F-PLN DISCONTINUITY -) ----------------------------
			
			setprop(f_pln_disp~ "l2/id", "");
			
			setprop(f_pln_disp~ "l2/time", "");
			
			setprop(f_pln_disp~ "l2/spd_alt", "");
			
			# L3 TO L5 WAYPOINTS -----------------------------------------------
			
			for (var wp = 1; wp <= 3; wp += 1) {
			
				var id = getprop(rm_route~ "route/wp[" ~ wp ~ "]/id");
				
				if (id != nil) {
				
					setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/id", id);
				
					var time_min = int(getprop(rm_route~ "route/wp[" ~ wp ~ "]/leg-time"));
					
					# Change time to string with 4 characters
					
					if (time_min < 10)
						setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/time", "000" ~ time_min);
					elsif (time_min < 100)
						setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/time", "00" ~ time_min);
					elsif (time_min < 100)
						setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/time", "0" ~ time_min);
					else
						setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/time", time_min);
						
					var spd = getprop(rm_route~ "route/wp[" ~ wp ~ "]/ias-mach");
					
					var alt = getprop(rm_route~ "route/wp[" ~ wp ~ "]/altitude-ft");
					
					var spd_str = "";
					
					var alt_str = "";
					
					# Check if speed is IAS or mach, if Mach, display M.xx
					
					if (spd == nil)
						spd = 0;
					
					if (spd == 0)
						spd_str = "---";
					elsif (spd < 1)
						spd_str = "M." ~ (100 * spd);
					else
						spd_str = spd;
						
					# Check if Alt is in 1000s or FL
					
					if (alt == nil)
						alt = 0;
					
					if (alt == 0)
						alt_str = "----";
					elsif (alt > 9999)
						alt_str = "FL" ~ int(alt / 100);
					else
						alt_str = alt;
						
					setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/spd_alt", spd_str ~ "/" ~ alt_str);
					# Don't Show - END OF F-PLN -
					
					setprop(f_pln_disp~ "eof", 0);
						
				} else {
				
					setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/id", "");
			
					setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/time", "");
			
					setprop(f_pln_disp~ "l" ~ (wp + 2) ~ "/spd_alt", "");
					
					# Show - END OF F-PLN -
					
					setprop(f_pln_disp~ "eof", 1);
				
				} # End of if (id != nil) ... else ...
			
			} # End of L3 to L5 For Loop
		
		} # End of first page check
		
		else {
		
			var first = getprop(f_pln_disp~ "first");
		
			for (var l = 1; l <= 5; l += 1) {
			
				var wp = first - 2 + l;
				
				var id = getprop(rm_route~ "route/wp[" ~ wp ~ "]/id");				
				
				if (id != nil) {
				
					setprop(f_pln_disp~ "l" ~ l ~ "/id", id);
				
					var time_min = getprop(rm_route~ "route/wp[" ~ wp ~ "]/leg-time");
					
					# Change time to string with 4 characters
					
					if (time_min < 10)
						setprop(f_pln_disp~ "l" ~ l ~ "/time", "000" ~ time_min);
					elsif (time_min < 100)
						setprop(f_pln_disp~ "l" ~ l ~ "/time", "00" ~ time_min);
					elsif (time_min < 100)
						setprop(f_pln_disp~ "l" ~ l ~ "/time", "0" ~ time_min);
					else
						setprop(f_pln_disp~ "l" ~ l ~ "/time", time_min);
						
					var spd = getprop(rm_route~ "route/wp[" ~ wp ~ "]/ias-mach");
					
					var alt = getprop(rm_route~ "route/wp[" ~ wp ~ "]/altitude-ft");
					
					var spd_str = "";
					
					var alt_str = "";
					
					# Check if speed is IAS or mach, if Mach, display M.xx
					
					if ((spd == 0) or (spd == nil))
						spd_str = "---";
					elsif (spd < 1)
						spd_str = "M." ~ (100 * spd);
					else
						spd_str = spd;
						
					# Check if Alt is in 1000s or FL
					
					if (alt == 0)
						alt_str = "----";
					elsif (alt > 9999)
						alt_str = "FL" ~ int(alt / 100);
					else
						alt_str = alt;
						
					setprop(f_pln_disp~ "l" ~ l ~ "/spd_alt", spd_str ~ "/" ~ alt_str);
					# Don't Show - END OF F-PLN -
					
					setprop(f_pln_disp~ "eof", 0);
						
				} else {
				
					setprop(f_pln_disp~ "l" ~ l ~ "/id", "");
			
					setprop(f_pln_disp~ "l" ~ l ~ "/time", "");
			
					setprop(f_pln_disp~ "l" ~ l ~ "/spd_alt", "");
					
					# Show - END OF F-PLN -
					
					setprop(f_pln_disp~ "eof", 1);
				
				} # End of if (id != nil) ... else ...
			
			} # End of L1 to L5 Loop
		
		} # End of NOT First Page
	
	}

};
