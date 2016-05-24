# LAT and VER REV pages are managed separately

var rm_route = "/autopilot/route-manager/";

var f_pln_disp = "/instrumentation/mcdu/f-pln/disp/";

var NM2M = 1852;

var f_pln = {
	updating_wpts: 0,
	missed_strung: 0,
	init_f_pln : func {
		print('Init F-PLN');
	
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
		
		setprop(f_pln_disp~ 'current-flightplan', '');
		setprop(f_pln_disp~ 'departure', '');
		setprop(f_pln_disp~ 'destination', '');
    
		setprop("flight-management/alternate/icao", 'empty');
		
	
		fmgc.RouteManager.deleteFlightPlan('temporary');
		fmgc.RouteManager.deleteAlternateDestination();
		
		## Set Departure and Destination from active RTE
		
		var dep = getprop(active_rte~ "depicao");
		
		var arr = getprop(active_rte~ "arricao");
		
		var fp = flightplan();

		var depAp = findAirportsByICAO(dep)[0];
		var arrAp = findAirportsByICAO(arr)[0];

		# FG3.7 (version/3.7.0-7-gf4fa687) returns NaN for distance
		# without departure runway, so pick a default.
		var depRwy = depAp.findBestRunwayForPos(geo.aircraft_position());
		# FG as far back as 3.4 and as recent as 3.7 return
		# nonsensical (though finite) distance without destination
		# runway, so pick a default as well.
		var arrRwy = arrAp.findBestRunwayForPos(geo.aircraft_position());

		fp.departure = depAp;
		fp.departure_runway = depRwy;

		fp.destination = arrAp;
		fp.destination_runway = arrRwy;
		
		setprop(f_pln_disp~ 'departure', dep);
		setprop(f_pln_disp~ 'destination', arr);

		if(getprop("/flight-management/alternate/icao") == "empty") {
			# artix: disabled this
                        #setprop(rm_route~ "input", "@INSERT99:" ~ dep ~ "@0");
		
		} else {
		
			#setprop(rm_route~ "input", "@INSERT99:" ~ getprop("/flight-management/alternate/icao") ~ "@0");
		
		}
		
		## Copy Waypoints and altitudes from active-rte
		
		for (var index = 0; getprop(active_rte~ "route/wp[" ~ index ~ "]/wp-id") != nil; index += 1) {
		
			var wp_id = getprop(active_rte~ "route/wp[" ~ index ~ "]/wp-id");
			
			var wp_alt = getprop(active_rte~ "route/wp[" ~ index ~ "]/altitude-ft");
		
			if (wp_alt == nil)
				wp_alt = 10000;
		
			setprop(rm_route~ "input", "@INSERT" ~ (index + 1) ~ ":" ~ wp_id ~ "@" ~ wp_alt);
		
		}
		
		# Copy Speeds to Route Manager Property Tree
		
		var max_wp = getprop(rm_route~ "route/num");
		
		for (var wp = 0; wp < max_wp; wp += 1) {
		
			var wp_spd = getprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach");
			
			if (wp_spd != nil)
				setprop(rm_route~ "route/wp[" ~ wp ~ "]/ias-mach", wp_spd);
		
		}
		
		## Calculate Times to each WP starting with FROM at 0000 and using determined speeds
		
		setprop(rm_route~ "route/wp/leg-time", 0);
		
		for (var wp = 1; wp < getprop(rm_route~ "route/num"); wp += 1) {
		
			var dist = getprop(rm_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-distance-nm");
			
			var spd = getprop(rm_route~ "route/wp[" ~ wp ~ "]/ias-mach");
			
			var alt = getprop(rm_route~ "route/wp[" ~ wp ~ "]/altitude-ft");
			
			var gs_min = 0; # Ground Speed in NM/min
			
			if ((spd == nil) or (spd <= 0)) {
			
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
			var time_h = dist / gs_min;
			var time_min = int(60 * time_h);
			
			var last_time = getprop(rm_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-time") or 0;
			
			if (wp == 1)
			    last_time = last_time + 30;
				
			# Atm, using 30 min for taxi time. You will be able to change this in INIT B when it's completed
			
			var total_time = last_time + time_min;
			
			setprop(rm_route~ "route/wp[" ~ wp ~ "]/leg-time", total_time);
		
		}
		var fp = flightplan();
		var sz = fp.getPlanSize();
		var first_wp = fp.getWP(0);
		if(sz > 1){
			if(sz == 2){
				fmgc.RouteManager.setDiscontinuity(first_wp.id);
			} else {
				var first_route_wp = fp.getWP(1);
				if(first_route_wp.wp_role != 'sid')
					fmgc.RouteManager.setDiscontinuity(first_wp.id);
				var last_route_wp = fmgc.RouteManager.getLastEnRouteWaypoint();
				if(last_route_wp != nil)
					fmgc.RouteManager.setDiscontinuity(last_route_wp.id);
			}
		}
		me.update_disp();
		
		setprop("/autopilot/route-manager/current-wp", 0);
		setprop("instrumentation/efis/inputs/plan-wpt-index", 0);
		setprop("instrumentation/efis[1]/inputs/plan-wpt-index", 0);
		me.missed_strung = 0;
		#setprop(rm_route~ "active", 1); # TRICK: refresh canvas
		#setprop(rm_route~ "active", 0);
	
	},
		
	init_sec_f_pln : func {

		print('Init SEC F-PLN');

		setprop("flight-management/alternate/secondary/icao", 'empty');
		fmgc.RouteManager.deleteAlternateDestination('secondary');

		## Copy Waypoints and altitudes from active-rte
		var fp = fmgc.RouteManager.createSecondaryFlightPlan(1);
		var dep = getprop(sec_rte~ "depicao");
		var arr = getprop(sec_rte~ "arricao");
		var old_actv = getprop(rm_route~ "active");
		if(fp.departure != nil and fp.departure.id == dep)
			fp.departure = airportinfo(arr); #trick used to force update
		fp.departure = airportinfo(dep);
		if(fp.destination != nil and fp.destination.id == arr)
			fp.destination = airportinfo(dep); #trick used to force update
		fp.destination = airportinfo(arr);
		setprop(rm_route~ "active", old_actv);

		var wp_count = 0;
		for (var index = 0; getprop(sec_rte~ "route/wp[" ~ index ~ "]/wp-id") != nil; index += 1){
			wp_count += 1;
		}
		#if(wp_count){
		#	while(fp.getPlanSize()) fp.deleteWP(0); #CLEAR any waypoint
		#}

		var idx_offs = (fp.getPlanSize() > 1 ? 1 : 0);

		for (var index = 0; index < wp_count; index += 1) {

			var wp_id = getprop(sec_rte~ "route/wp[" ~ index ~ "]/wp-id");

			var wp_alt = getprop(sec_rte~ "route/wp[" ~ index ~ "]/altitude-ft");

			var wp = me.create_wp(wp_id);
			if(wp != nil){
				var wpidx = fp.getPlanSize() - idx_offs;
				fp.insertWP(wp, wpidx);
				if(wp_alt != nil){
					wp = fp.getWP(wpidx);
					wp.setAltitude(wp_alt, 'at');
				}
			}

		}

		# Copy Speeds to Route Manager Property Tree

		var max_wp = fp.getPlanSize();

		for (var wp = 0; wp < max_wp; wp += 1) {
			var wpt = fp.getWP(wp);
			var wp_spd = getprop(sec_rte~ "route/wp[" ~ wp ~ "]/ias-mach");

			if (wp_spd != nil)
				wpt.setSpeed(wp_spd, 'at');

		}

		if(getprop("/flight-management/alternate/icao") == "empty") {
			# artix: disabled this
			#setprop(rm_route~ "input", "@INSERT99:" ~ dep ~ "@0");

		} else {
			#TODO!!!
			#setprop(rm_route~ "input", "@INSERT99:" ~ getprop("/flight-management/alternate/icao") ~ "@0");

		}

		## Calculate Times to each WP starting with FROM at 0000 and using determined speeds
		var sec_route = 'flight-management/secondary-rte/';
		setprop(sec_route~ "route/wp/leg-time", 0);

		for (var wp = 1; wp < max_wp; wp += 1) {
			var wpt = fp.getWP(wp);
			
			var dist = wpt.leg_distance;

			var spd = wpt.speed_cstr;

			var alt = wpt.alt_cstr;

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
			var time_h = dist / gs_min;
			var time_min = int(60 * time_h);

			var last_time = getprop(sec_route~ "route/wp[" ~ (wp - 1) ~ "]/leg-time") or 0;

			if (wp == 1)
				last_time = last_time + 30;

			# Atm, using 30 min for taxi time. You will be able to change this in INIT B when it's completed

			var total_time = last_time + time_min;
			#TODO: fix this also for TMPY
			#setprop(sec_route~ "route/wp[" ~ wp ~ "]/leg-time", total_time);

		}
		var first_wp = fp.getWP(0);
		if(max_wp > 1){
			if(max_wp == 2){
				fmgc.RouteManager.setDiscontinuity(first_wp.id, 'secondary');
			} else {
				var first_route_wp = fp.getWP(1);
				if(first_route_wp.wp_role != 'sid')
					fmgc.RouteManager.setDiscontinuity(first_wp.id, 'secondary');
				var last_route_wp = fmgc.RouteManager.getLastEnRouteWaypoint('secondary');
				if(last_route_wp != nil)
					fmgc.RouteManager.setDiscontinuity(last_route_wp.id, 'secondary');
			}
		}
		setprop('instrumentation/mcdu/sec-f-pln/created', 1);
		#me.update_disp();

		#setprop("/autopilot/route-manager/current-wp", 0);
		#setprop("instrumentation/efis/inputs/plan-wpt-index", 0);
		#setprop("instrumentation/efis[1]/inputs/plan-wpt-index", 0);
		#setprop(sec_route~ "active", 1); # TRICK: refresh canvas
		#setprop(sec_route~ "active", 0);

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
		
		mcdu.display_message("F-PLN SAVED TO ACTIVE RTE");
	
	},
	get_flightplan_id: func(){
		var current_fp = getprop(f_pln_disp~ "current-flightplan");
		if(current_fp == nil or current_fp == ''){
			current_fp = 'current';
		}
		return current_fp;
	},
	get_current_flightplan: func(){
		var current_fp = me.get_flightplan_id();
		fmgc.RouteManager.update();
		return fmgc.RouteManager.getFlightPlan(current_fp);
	},
	revise_flightplan: func(){
		var actv = getprop('autopilot/route-manager/active');
		if(!actv) return me.get_current_flightplan();
		var cur_id = me.get_flightplan_id();
		if(cur_id == 'secondary') return me.get_current_flightplan();
		if(cur_id != 'temporary'){
			return me.copy_to_tmpy();
		}
		return me.get_current_flightplan();
	},
	copy_to_tmpy: func(){
		var fp = fmgc.RouteManager.createTemporaryFlightPlan();
		setprop(f_pln_disp~ 'current-flightplan', 'temporary');
		f_pln.update_disp();
		return fp;
	},
	first_displayed_wp: func(){
		#me.update_flightplan_waypoints();
		var first = getprop(f_pln_disp~ "first") or 0;
		me.get_wp(first);
	},
	get_wp: func(idx){
		var wpts = me['waypoints'];
		if(wpts == nil) return nil;
		if(idx >= size(wpts)) return nil;
		var wp = wpts[idx];
		if(typeof(wp) == 'scalar' and wp == '---') return nil;
		return wp;
	},
	insert_procedure_wp: func(type, proc_wp, idx){
		var fp = me.get_current_flightplan();
		var lat = num(string.trim(proc_wp.wp_lat));
		var lon = num(string.trim(proc_wp.wp_lon));
		if( (lat == 0 and lon == 0) or 
			(math.abs(lat) > 90) or 
			(math.abs(lon) > 180) or 
			(proc_wp.wp_type == 'Intc') or 
			(proc_wp.wp_type == 'Hold') ) {
				return nil;
			}
		var wp_pos = {
			lat: lat,
			lon: lon
		};
		var wpt = createWP(wp_pos, proc_wp.wp_name, type);
		#wpt.wp_role = 'sid';
		print('Insert '~type~' WP '~proc_wp.wp_name ~ ' at ' ~ idx);
		fp.insertWP(wpt, idx);
		wpt = fp.getWP(idx);
		if(proc_wp.alt_cstr_ind)
			wpt.setAltitude(proc_wp.alt_cstr, 'at');
		if(proc_wp.spd_cstr_ind)
			wpt.setSpeed(proc_wp.spd_cstr, 'at');
		var fly_type = string.lc(string.trim(proc_wp.fly_type));
		if(fly_type == 'fly-over'){
			wpt.fly_type = 'flyOver';
		}
		return wpt;
	},
	insert_wp: func(new_wp, line){
		var fp = me.get_flightplan_at_line(line);
		var wp = me.get_wp_at_line(line);
		if(typeof(new_wp) == 'scalar'){
			new_wp = me.create_wp(new_wp);
		}
		if(new_wp == nil) return nil;
		var idx = -1;
		if(fp == nil) return nil;
		if(!me.is_alternate_line(line))
			fp = me.revise_flightplan();
		if(fp == nil) return nil;
		if(wp != nil){
			idx = wp.index;
			fmgc.RouteManager.insertWP(new_wp, idx, fp.id);
		} else {
			if(getprop(f_pln_disp~ "l" ~ line ~ '/end-marker'))
				fmgc.RouteManager.appendWP(new_wp, fp.id);
			elsif(getprop(f_pln_disp~ "l" ~ line ~ '/discontinuity-marker')){
				idx = getprop(f_pln_disp~ "l" ~ line ~ '/wp-index');
				if(idx < 0) return nil;
				var wp = fp.getWP(idx);
				if(wp == nil) return nil;
				idx += 1;
				fmgc.RouteManager.insertWP(new_wp, idx, fp.id);
				fmgc.RouteManager.clearDiscontinuity(wp.id, fp.id);
				fmgc.RouteManager.setDiscontinuity(new_wp.id, fp.id);
				fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
			}
		}
		if(idx >= 0){
			fmgc.RouteManager.updateFlightPlan(fp.id);
			var dest_wp = fmgc.RouteManager.getDestinationWP(fp.id);
			if(dest_wp != nil  and idx > dest_wp.index){
				var wp = fp.getWP(idx);
				if(wp.id == new_wp.id)
					wp.wp_role = 'missed';
			}
		}
		me.update_disp();
		return new_wp;
	},
	del_wp : func (line) {
		var fp = me.get_flightplan_at_line(line);
		var wp = me.get_wp_at_line(line);
		var idx = -1;
		if(fp != nil and wp != nil){
			idx = wp.index;
			if(!me.is_alternate_line(line))
				fp = me.revise_flightplan();
			fmgc.RouteManager.deleteWP(idx, fp.id);
		}
		elsif(fp != nil and wp == nil){
			if(getprop(f_pln_disp~ "l" ~ line ~ '/end-marker'))
				return;
			elsif(getprop(f_pln_disp~ "l" ~ line ~ '/discontinuity-marker')){
				idx = getprop(f_pln_disp~ "l" ~ line ~ '/wp-index');
				if(idx < 0) return nil;
				if(!me.is_alternate_line(line))
					fp = me.revise_flightplan();
				var wp = fp.getWP(idx);
				if(wp == nil) return nil;
				fmgc.RouteManager.clearDiscontinuity(wp.id, fp.id);
				fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
			}
		}
		me.update_disp();
	},
	toggle_overfly: func(line){
		if(!getprop('/instrumentation/mcdu/overfly-mode')) return;
		if(!me.is_alternate_line(line))
			me.revise_flightplan();
		var wp = me.get_wp_at_line(line);
		if(wp != nil){
			var fly_type = wp.fly_type;
			if(fly_type != 'flyOver')
				wp.fly_type = 'flyOver';
			else 
				wp.fly_type = 'flyBy';
			fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
			me.update_disp();
		}
		setprop('/instrumentation/mcdu/overfly-mode', 0);
	},
	get_destination_wp: func(){
		if(fmgc.RouteManager.sequencing) return nil;
		var f= me.get_current_flightplan(); 
		var current_fp = getprop(f_pln_disp~ "current-flightplan");
		if(current_fp == nil or current_fp == ''){
			current_fp = 'current';
		}
		var numwp = f.getPlanSize();
		var lastidx = numwp - 1;
		var wp_info = nil;
		fmgc.RouteManager.update(current_fp);
		var wp = fmgc.RouteManager.getDestinationWP(current_fp);
		if(wp != nil){
			wp_info = wp;
		}
		return wp_info;
	},
	get_destination_airport: func(){
		if(fmgc.RouteManager.sequencing) return nil;
		var f= me.get_current_flightplan();
		return f.destination;
	},
	enable_alternate: func(wp_idx){
		if(getprop("/instrumentation/mcdu/f-pln/enabling-altn")) return;
		var cur_id = me.get_flightplan_id();
		if(cur_id == 'secondary') return;
		if(cur_id == 'temporary') cur_id = 'current';
		var altn = fmgc.RouteManager.getAlternateRoute(cur_id);
		if(altn == nil) return;
		var fp = me.revise_flightplan();
		cur_id = fp.id;
		var wp = fp.getWP(wp_idx);
		if(wp != nil) fmgc.RouteManager.setDiscontinuity(wp.id, cur_id);
		fmgc.RouteManager.deleteWaypointsAfter(wp_idx, cur_id);
		var wp_count = fp.getPlanSize();
		fp.destination = altn.destination;
		if(fp.getPlanSize() > wp_count)
			fp.deleteWP(fp.getPlanSize() - 1);
		var altn_size = altn.getPlanSize();
		for(var i = 0; i < altn_size; i += 1){
			var wp = fmgc.RouteManager.copyWP(altn, fp, i);
		}
		setprop("/instrumentation/mcdu/f-pln/enabling-altn", 1);
		me.update_disp();
		fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
	},
	update_flightplan_waypoints: func(){
		if(me.updating_wpts) return;
		if(fmgc.RouteManager.sequencing) return;
		me.updating_wpts = 1; 
		var first = getprop(f_pln_disp~ "first");
		if(first == nil or first == '') first = 0;
		var current_fp = getprop(f_pln_disp~ "current-flightplan");
		if(current_fp == nil or current_fp == ''){
			current_fp = 'current';
		}
		var fp = fmgc.RouteManager.getFlightPlan(current_fp);
		var fpsize = fp.getPlanSize();
		var wpts = [];
		var cur_wp = nil;
		if(current_fp == 'current')
			cur_wp = fp.getWP();
		me.to_wpt_idx = -1;
		me.from_wpt_idx = -1;
		me.to_wpt_line = -1;
		me.from_wpt_line = -1;
		for(var i = 0; i < fpsize; i += 1){
			var wp = fp.getWP(i);
			var real_idx = size(wpts);
			append(wpts, wp);
			var wp_id = wp.id;
			if(cur_wp != nil and cur_wp.id == wp_id){
				me.to_wpt_idx = real_idx;
				me.from_wpt_idx = real_idx - 1;
				me.to_wpt_line = me.to_wpt_idx - first;
				me.from_wpt_line = me.from_wpt_idx - first;
			}
			if(fmgc.RouteManager.hasDiscontinuity(wp_id, current_fp))
				append(wpts, '---');
		}
		var altn_rte = fmgc.RouteManager.getAlternateRoute(current_fp);
		var enabling_altn = getprop("/instrumentation/mcdu/f-pln/enabling-altn");
		if(altn_rte != nil and !enabling_altn){
			append(wpts, '---');
			me.altn_offset = size(wpts);
			var altn_size = altn_rte.getPlanSize();
			for(var i = 0; i < altn_size; i += 1){
				var wp = altn_rte.getWP(i);
				var real_idx = size(wpts);
				append(wpts, wp);
				var wp_id = wp.id;
				if(cur_wp != nil and cur_wp.id == wp_id){
					me.to_wpt_idx = real_idx;
					me.from_wpt_idx = real_idx - 1;
					me.to_wpt_line = me.to_wpt_idx - first;
					me.from_wpt_line = me.from_wpt_idx - first;
				}
				if(fmgc.RouteManager.hasDiscontinuity(wp_id, altn_rte.id))
					append(wpts, '---');
			}
		} else {
			me.altn_offset = -1;
		}
		me.waypoints = wpts;
		me.updating_wpts = 0;
	},
	update_disp : func {
	
		# This function is simply to update the display in the Active Flight Plan Page. This gets first wp ID and then places the others accordingly.
		if(fmgc.RouteManager.sequencing) return nil;
		me.update_flightplan_waypoints();
		
		var first = getprop(f_pln_disp~ "first");
		var current_fp = getprop(f_pln_disp~ "current-flightplan");
		if(current_fp == nil or current_fp == ''){
			current_fp = 'current';
		}
		var fp = fmgc.RouteManager.getFlightPlan(current_fp);
		var fpsize = fp.getPlanSize();
		var fp_tree = rm_route~ "flightplan/"~current_fp~"/route/";
		
		var hold = getprop("/flight-management/hold/wp_id") or 0;
		
		# Calculate times
		
		for (var wp = 1; wp < fpsize; wp += 1) {
			
			var waypoint = fp.getWP(wp);
		
			var dist = waypoint.leg_distance;
			
			var spd = waypoint.speed_cstr;
			
			var alt = waypoint.alt_cstr;
			
			var gs_min = 0; # Ground Speed in NM/min
			
			if ((spd == nil) or (spd <= 0)) {
			
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
			var time_h = dist / gs_min;
			
			var time_min = int(time_h * 60);
			
			var last_time = getprop(fp_tree~ "wp[" ~ (wp - 1) ~ "]/leg-time") or 0;
			
			if (wp == 1)
				last_time = last_time + 30;
			# Atm, using 30 min for taxi time. You will be able to change this in INIT B when it's completed
			
			var total_time = last_time + time_min;
			
			setprop(fp_tree~ "wp[" ~ wp ~ "]/leg-time", total_time);
		
		}
		
		# Destination details --------------------------------------------------
		
		var cur_tpy = (current_fp == 'current' or current_fp == 'temporary');
		
		if (fpsize >= 2) {
			fmgc.RouteManager.update(current_fp);
			var destWP = fmgc.RouteManager.getDestinationWP(current_fp);
			var dest_id = fpsize - 1;
			if(destWP == nil) destWP = fp.getWP(dest_id);
			if(destWP != nil) dest_id = destWP.index;
			#var destWP = fp.getWP(dest_id);
		
			var dest_name = destWP.wp_name;
		
			var dest_time = getprop(fp_tree~ "wp[" ~ dest_id ~ "]/leg-time");

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
		
			if(0){
				# Set Airborne to get distance to last waypoint
				var old_actv = getprop(rm_route~ "active");

				setprop(rm_route~ "active", 1);

				setprop(rm_route~ "airborne", 1);

				var rte_dist = getprop(rm_route~ "wp-last/dist");

				setprop(rm_route~ "active", old_actv);
			}
			
			var rte_dist = fmgc.RouteManager.getDistance(current_fp, 1);
	
			setprop(f_pln_disp~ "dest", dest_name);
		
			setprop(f_pln_disp~ "time", dest_time_str);
		
			if (rte_dist != nil and rte_dist != 0)
				setprop(f_pln_disp~ "dist", int(rte_dist));
			else
				setprop(f_pln_disp~ "dist", "----");
			
		} else {
		
			setprop(f_pln_disp~ "dest", "----");
			
			setprop(f_pln_disp~ "time", "----");
			
			setprop(f_pln_disp~ "dist", "----");
		
		}
		
		var show_hold = 0;
		
		var wpsize = size(me.waypoints);
		var DISCONTINUITY_MARKER =  "-------    F-PLN DISCONTINUITY    -------";
		var END_MARKER =			"-----------    END OF F-PLN    -----------";
		var ALT_END_MARKER =		"----------  END OF ALTN F-PLN  ----------";
		#var NO_ALTN_MARKER = 		"";
		var no_altn = (me.altn_offset < 0);
		for (var l = 1; l <= 5; l += 1) {
			var wp = first - 1 + l;
			var line_id = 'l'~l;
			if(wp == wpsize){
				var marker = (no_altn ? END_MARKER : ALT_END_MARKER);
				setprop(f_pln_disp~ line_id~ "/id", marker);
				setprop(f_pln_disp~ line_id~ "/time", '');
				setprop(f_pln_disp~ line_id~ "/spd_alt", '');
				setprop(f_pln_disp~ line_id~ "/end-marker", 1);
				setprop(f_pln_disp~ line_id~ "/discontinuity-marker", 0);
				setprop(f_pln_disp~ line_id~ "/ovfly", '');
				setprop(f_pln_disp~ line_id~ "/from-wpt", 0);
				setprop(f_pln_disp~ line_id~ "/to-wpt", 0);
				setprop(f_pln_disp~ line_id~ "/missed", 0);
				setprop(f_pln_disp~ line_id~ "/wp-index", -1);
				setprop(f_pln_disp~ line_id~ "/alternate", !no_altn);
			}
			elsif(wp > wpsize){
				setprop(f_pln_disp~ line_id~ "/id", "");
				setprop(f_pln_disp~ line_id~ "/time", '');
				setprop(f_pln_disp~ line_id~ "/spd_alt", '');
				setprop(f_pln_disp~ line_id~ "/end-marker", 0);
				setprop(f_pln_disp~ line_id~ "/discontinuity-marker", 0);
				setprop(f_pln_disp~ line_id~ "/ovfly", '');
				setprop(f_pln_disp~ line_id~ "/from-wpt", 0);
				setprop(f_pln_disp~ line_id~ "/to-wpt", 0);
				setprop(f_pln_disp~ line_id~ "/missed", 0);
				setprop(f_pln_disp~ line_id~ "/wp-index", -1);
				setprop(f_pln_disp~ line_id~ "/alternate", 0);
			} else {
				var fp_wp = me.waypoints[wp];
				if(typeof(fp_wp) == 'scalar' and fp_wp == '---'){
					var eof_marker = (!no_altn and wp == (me.altn_offset - 1));
					var marker = (eof_marker ? END_MARKER : DISCONTINUITY_MARKER);
					var wp_index = -1;
					if(!eof_marker and wp > 0){
						var prev_wp = me.waypoints[wp - 1];
						if(prev_wp != nil and typeof(prev_wp) != 'scalar')
							wp_index = prev_wp.index;
					}
					setprop(f_pln_disp~ line_id~ "/id", marker);
					setprop(f_pln_disp~ line_id~ "/time", '');
					setprop(f_pln_disp~ line_id~ "/spd_alt", '');
					setprop(f_pln_disp~ line_id~ "/end-marker", eof_marker);
					setprop(f_pln_disp~ line_id~ "/discontinuity-marker", !eof_marker);
					setprop(f_pln_disp~ line_id~ "/from-wpt", 0);
					setprop(f_pln_disp~ line_id~ "/to-wpt", 0);
					setprop(f_pln_disp~ line_id~ "/missed", 0);
					setprop(f_pln_disp~ line_id~ "/wp-index", wp_index);
					setprop(f_pln_disp~ line_id~ "/alternate", 0);
				} else {
					var id = fp_wp.id;
					var fly_type = fp_wp.fly_type;
					setprop(f_pln_disp~ line_id~ "/id", id);
					var ovfly_sym = (fly_type == 'flyOver' ? 'D' : '');
					setprop(f_pln_disp~ line_id~ "/ovfly", ovfly_sym);
					setprop(f_pln_disp~ line_id~ "/wp-index", fp_wp.index);

					var time_min = int(getprop(fp_tree~ "wp[" ~ fp_wp.index ~ "]/leg-time") or 0);

					# Change time to string with 4 characters

					if (time_min < 10)
						setprop(f_pln_disp~ line_id~ "/time", "000" ~ time_min);
					elsif (time_min < 100)
						setprop(f_pln_disp~ line_id~ "/time", "00" ~ time_min);
					elsif (time_min < 100)
						setprop(f_pln_disp~ line_id~ "/time", "0" ~ time_min);
					else
						setprop(f_pln_disp~ line_id~ "/time", time_min);

					var spd = fp_wp.speed_cstr;

					var alt = fp_wp.alt_cstr;

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
					var is_altn = (me.altn_offset > 0 and wp >= me.altn_offset);
					setprop(f_pln_disp~ line_id~ "/spd_alt", spd_str ~ "/" ~ alt_str);
					setprop(f_pln_disp~ line_id~ "/end-marker", 0);
					setprop(f_pln_disp~ line_id~ "/discontinuity-marker", 0);
					setprop(f_pln_disp~ line_id~ "/from-wpt", (me.from_wpt_line == l));
					setprop(f_pln_disp~ line_id~ "/to-wpt", (me.to_wpt_line == (l - 1)));
					setprop(f_pln_disp~ line_id~ "/missed", 
							fmgc.RouteManager.isMissedApproach(fp_wp, current_fp));
					setprop(f_pln_disp~ line_id~ "/alternate", is_altn);
					if(hold and hold == fp_wp.index){
						show_hold = 1;
						setprop("/instrumentation/mcdu/f-pln/hold-id", l - 1);
					}
				}
			}
		}
		var dep = '';
		var arr = '';
		var dp = fp.departure;
		if(dp != nil) dep = dp.id;
		var dst = fp.destination;
		if(dst != nil) arr = dst.id;
		setprop(f_pln_disp~ 'departure', dep);
		setprop(f_pln_disp~ 'destination', arr);
		setprop("/instrumentation/mcdu/f-pln/show-hold", show_hold);
	
	},
	is_alternate_line: func(line){
		getprop(f_pln_disp~ "l" ~ line ~ '/alternate');
	},
	get_flightplan_at_line: func(line){
		if(fmgc.RouteManager.sequencing) return nil;
		var fp =  nil;
		var is_altn = me.is_alternate_line(line);
		if(!is_altn){
			fp = me.get_current_flightplan();
		} else {
			var cur_id = me.get_flightplan_id();
			fp = fmgc.RouteManager.getAlternateRoute(cur_id);
		}
		return fp;
	},
	get_wp_at_line: func(line){
		if(fmgc.RouteManager.sequencing) return nil;
		var idx = getprop(f_pln_disp~ "l" ~ line ~ '/wp-index');
		if(idx == nil or idx == '') return nil;
		var wp = nil;
		if(idx >= 0){
			var is_disc = getprop(f_pln_disp~ "l" ~ line ~ '/discontinuity-marker');
			if(is_disc) return nil;
			var fp = me.get_flightplan_at_line(line);
			if(fp != nil) wp = fp.getWP(idx);
		}
		return wp;
	},
	get_idx_at_line: func(line){
		var idx = getprop(f_pln_disp~ "l" ~ line ~ '/wp-index');
		if(idx == nil or idx == '') return -1;
		return idx;
	},
	set_restriction: func(line, alt, spd){
		#if(spd != nil)
		#	setprop("autopilot/route-manager/route/wp[" ~ (first) ~ "]/ias-mach", spd);
		#if(alt != nil)
		#	setprop("autopilot/route-manager/route/wp[" ~ (first) ~ "]/altitude-ft", alt);
		if(fmgc.RouteManager.sequencing) return nil;
		var wp = me.get_wp_at_line(line);
		if(spd != nil)
			wp.setSpeed(spd, 'at');
		if(alt != nil)
			wp.setAltitude(alt, 'at');
		fmgc.RouteManager.trigger(fmgc.RouteManager.SIGNAL_FP_EDIT);
	},
	dir_to: func(wp_or_idx, opts = nil){
		var actv = getprop('autopilot/route-manager/active');
		var cur_fp_id = me.get_flightplan_id();
		if(!actv or cur_fp_id == 'temporary') return;
		var wp = nil;
		var idx = -1;
		var fp = fmgc.RouteManager.flightplan;
		var sz = fp.getPlanSize();
		var cur_wp = fp.getWP();
		if(cur_wp == nil or cur_wp.index == 0) return;
		if(typeof(wp_or_idx) == 'scalar'){
			var n = num(wp_or_idx);
			if(n != nil){
				idx = n;
				if(idx <= cur_wp.index or idx >= sz) return;
				wp = fp.getWP(idx);
			} else {
				wp = fmgc.RouteManager.findWaypointByID(wp_or_idx);
				if(wp != nil) idx = wp.index;
				if(wp == nil){
					wp = me.create_wp(wp_or_idx);
					if(wp == nil) return;
				}
			}
		} else {
			wp = wp_or_idx;
			if(wp == nil) return;
			var fp_wp = fmgc.RouteManager.findWaypointByID(wp.id);
			if(fp_wp != nil) idx = fp_wp.index;
			if(idx >= 0 and (idx <= cur_wp.index or idx >= sz)) return;
		}
		if(wp == nil) return;
		var toWpDist = getprop("/autopilot/route-manager/wp/dist") or 0;
		if(idx >= 0) {
			if(idx == cur_wp.index) return;
			if(toWpDist < 1 and (idx + 1) == cur_wp.index) return;
		};
		var tpIdx = cur_wp.index;
		#var fromIdx = tpIdx + 1;
		#var offset_nm = 1;
		#if(toWpDist <= 1){
		#	offset_nm += 1;
		#	tpIdx += 1;
		#	if(idx >= 0 and tpIdx == idx) return;
		#}
		var tmpy_fp = fmgc.RouteManager.createTemporaryFlightPlan();
		setprop(f_pln_disp~ 'current-flightplan', 'temporary');
		setprop('/instrumentation/mcdu/f-pln/dir-to-mode', 1);
		if(idx > 0){
			var wpt_count = idx - tpIdx;
			fmgc.RouteManager.deleteWaypoints(tpIdx, wpt_count, 'temporary');
		}
		var tpWpt = me.create_tp_wp();
		fmgc.RouteManager.insertWP(tpWpt, tpIdx, 'temporary');
		tpIdx += 1;
		tpWpt = me.create_tp_wp(2);
		fmgc.RouteManager.insertWP(tpWpt, tpIdx, 'temporary');
		tpWpt = tmpy_fp.getWP(tpIdx);
		tpWpt.fly_type = 'overFly';
		if(idx < 0){
			fmgc.RouteManager.insertWP(wp, tpIdx + 1, 'temporary');
			fmgc.RouteManager.setDiscontinuity(tpIdx, 'temporary');
		}
		setprop('/flight-management/dir-to', tpIdx);
		me.update_disp();
	},
	string_missed_appr: func(){
		if(me.missed_strung) return;
		if(!fmgc.RouteManager.missed_approach_planned) return;
		var fp = flightplan();
		var sz = fp.getPlanSize();
		for(var i = 1; i < sz; i += 1){
			var wp = fp.getWP(i);
			var role = wp.wp_role;
			var type = wp.wp_type;
			if(role != 'approach' or type == 'runway') continue;
			fmgc.RouteManager.copyWP(fp, fp, wp.index, fp.getPlanSize());
		}
		me.missed_strung = 1;
	},
	create_wp: func(wp_id){
		if(wp_id == nil or string.trim(wp_id) == '') return nil;
		setprop('instrumentation/gps/scratch/result-count', 0);
		setprop('instrumentation/gps/scratch/query', wp_id);
		setprop('instrumentation/gps/scratch/type', '');
		setprop('instrumentation/gps/command', 'search');
		var results = getprop('instrumentation/gps/scratch/result-count');
		if(!results) return nil;
		var lat = getprop('instrumentation/gps/scratch/latitude-deg');
		var lon = getprop('instrumentation/gps/scratch/longitude-deg');
		var type = getprop('instrumentation/gps/scratch/type');
		var wp_pos = {
			lat: lat,
			lon: lon
		};
		var wp = createWP(wp_pos, wp_id);
		type = string.lc(type);
		if(type == 'fix' or type == 'vor' or type == 'ndb' or type == 'dme')
			type = 'navaid';
		else 
			type = 'basic';
		wp.wp_type = type;
		return wp;
	},
	create_tp_wp: func(offset_nm = 0){
		var xtrk_err = getprop('instrumentation/gps/wp/wp[1]/course-error-nm') or 0;
		var pos = nil;
		if(math.abs(xtrk_err) < 1){
			pos = me.pos_along_route(offset_nm);
		} else {
			pos = geo.aircraft_position();
			if(offset_nm != 0){
				var trk = fmgc.fmgc_loop.track;
				pos.apply_course_distance(trk, offset_nm * NM2M);
			}
		}
		return createWP(pos, '(T-P)', 'pseudo');
	},
	pos_along_route: func(offset_nm = 0){
		if(fmgc.RouteManager.sequencing) return nil;
		var fp = flightplan();
		var remaining = getprop("autopilot/route-manager/distance-remaining-nm") or 0;
		remaining -= offset_nm;
		return fp.pathGeod(-1, -remaining);
	}

};

var toggle_overfly = func(fp, wp_idx){
	if(!getprop('/instrumentation/mcdu/overfly-mode')) return;
	#var fp = flightplan();
	var wp = fp.getWP(wp_idx);
	if(wp != nil){
		var fly_type = wp.fly_type;
		if(fly_type != 'flyOver')
			wp.fly_type = 'flyOver';
		else 
			wp.fly_type = 'flyBy';
	}
	f_pln.update_disp();
	setprop('/instrumentation/mcdu/overfly-mode', 0);
}

setlistener(f_pln_disp~ 'current-flightplan', func(n){
	var cur = n.getValue();
	var rm = fmgc.RouteManager;
	if(rm.sequencing) return;
	var fp = rm.getFlightPlan(cur);
	var dep = '';
	var arr = '';
	if(fp != nil){
		var dp = fp.departure;
		if(dp != nil) dep = dp.id;
		var dst = fp.destination;
		if(dst != nil) arr = dst.id;
	}
	setprop(f_pln_disp~ 'departure', dep);
	setprop(f_pln_disp~ 'destination', arr);
	var fpln_title = '';
	var disp_sec = getprop('instrumentation/mcdu/sec-f-pln/disp');
	if(disp_sec == nil) disp_sec = 0;
#	if(!disp_sec and (!getprop(rm_route~ "active") or cur == 'temporary'))
#		fpln_title = 'TMPY';
	setprop(f_pln_disp~ 'pln-title', fpln_title);
}, 0, 1);

setlistener('autopilot/route-manager/current-wp', func(){
	if(fmgc.RouteManager.sequencing) return;
	var curpage = getprop('instrumentation/mcdu/page');
	if(curpage == 'f-pln'){
		mcdu.f_pln.update_disp();
	}
}, 0, 0);

setlistener('instrumentation/mcdu/sec-f-pln/disp', func(n){
	var disp_sec= n.getValue();
	var rm = fmgc.RouteManager;
	if(rm.sequencing) return;
	if(!disp_sec){
		if(rm.getFlightPlan('temporary') != nil)
			setprop(f_pln_disp~ 'current-flightplan', 'temporary');
		else
			setprop(f_pln_disp~ 'current-flightplan', '');
	}
	f_pln.update_disp();
}, 0, 0);

setlistener('flight-management/phase', func(n){
	var phase = n.getValue();
	if(phase == 'G/A'){
		f_pln.string_missed_appr();
	}
}, 0, 0);
