var co_tree = "/database/co_routes/";
var active_rte = "/flight-management/active-rte/";
var sec_rte = "/flight-management/secondary-rte/";
var altn_rte = "/flight-management/alternate/route/";
var sec_altn_rte = "/flight-management/alternate/secondary/route/";

setprop("/instrumentation/mcdu/from-to-results/line-length", 40);
setprop("/instrumentation/mcdu/input", "");

# Initialize with 0 Brightness

setprop("/instrumentation/mcdu/brt", 0);

# Set Default Tropo to 36090 (airbus default)

setprop("/flight-management/tropo", "36090");

# Empty Field Symbols are used when values are "empty" for strings and 0 for numbers, you set values with the functions when programming the FMGC

setprop(active_rte~ "id", "empty");
setprop(active_rte~ "depicao", "empty");
setprop(active_rte~ "arricao", "empty");
setprop(active_rte~ "flight-num", "empty");

setprop(sec_rte~ "id", "empty");
setprop(sec_rte~ "depicao", "empty");
setprop(sec_rte~ "arricao", "empty");
setprop(sec_rte~ "flight-num", "empty");

setprop("/flight-management/alternate/icao", "empty");
setprop("/flight-management/alternate/secondary/icao", "empty");
setprop(altn_rte~ "depicao", "empty");
setprop(altn_rte~ "arricao", "empty");
setprop(sec_altn_rte~ "depicao", "empty");
setprop(sec_altn_rte~ "arricao", "empty");

setprop("/flight-management/cost-index", 0);
setprop("/flight-management/crz_fl", 0);

var mCDU_init = {

	clear_active : func() {
	
		for(var i = 0; i < 100; i += 1) {
		
			if (getprop(active_rte~ "route/wp[" ~ i ~ "]/wp-id") != nil) {
		
				setprop(active_rte~ "route/wp[" ~ i ~ "]/wp-id", "");
				setprop(active_rte~ "route/wp[" ~ i ~ "]/altitude-ft", 0);
				setprop(active_rte~ "route/wp[" ~ i ~ "]/ias-mach", 0);
				
			}
		
		}
	
	},
	
	clear_sec : func() {

		for(var i = 0; i < 100; i += 1) {

			if (getprop(sec_rte~ "route/wp[" ~ i ~ "]/wp-id") != nil) {

				setprop(sec_rte~ "route/wp[" ~ i ~ "]/wp-id", "");
				setprop(sec_rte~ "route/wp[" ~ i ~ "]/altitude-ft", 0);
				setprop(sec_rte~ "route/wp[" ~ i ~ "]/ias-mach", 0);

			}

		}

	},

	co_rte : func (mcdu, id, secondary = 0) {
		var is_user_route = 0;
		var user_rte = '';
		if(substr(id, 0, 5) == 'user:'){
			id = substr(id, 5, size(id) - 5);
			user_rte = "/database/user_rtes/" ~ id ~ "/";
			is_user_route = 1;
		}

		if(!is_user_route){
			var rte_found = 0;
			for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {

				var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
				#print('"' ~ rte_id ~ '" == "' ~ id ~ '"' );
				if (rte_id == id) {
					rte_found = 1;
					var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
					var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");

					me.rte_sel(id, dep, arr, secondary);
					break;
				} 
			}
			if(!rte_found)
				display_message(MSG.NOT_IN_DB);
				#setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/input", "ERROR: NOT IN DATABASE");
		} else {

			var dep = getprop(user_rte~ "depicao");
			var arr = getprop(user_rte~ "arricao");

			me.rte_sel('user:'~id, dep, arr, secondary);
		}
		
		setprop("/flight-management/end-flight", 0);
		if(!secondary)
			f_pln.init_f_pln();
		else 
			f_pln.init_sec_f_pln();
	
	},
	
	rte_sel : func (id, dep, arr, secondary = 0) {
	
		# The Route Select function is the get the selected route and put those stuff into the active route
		var is_user_route = 0;
		var user_rte = '';
		if(substr(id, 0, 5) == 'user:'){
			id = substr(id, 5, size(id) - 5);
			user_rte = "/database/user_rtes/" ~ id ~ "/";
			is_user_route = 1;
		}
		
		var tree = (secondary ? sec_rte : active_rte);
		
		setprop(tree~ "id", id);
		setprop(tree~ "depicao", dep);
		setprop(tree~ "arricao", arr);
		
		if(is_user_route) 
			id = 'user:' ~ id;
		me.set_active_rte(id, secondary);
	
	},
	
	set_active_rte : func (id, secondary = 0) {
		var is_user_route = 0;
		var user_rte = '';
		if(substr(id, 0, 5) == 'user:'){
			id = substr(id, 5, size(id) - 5);
			user_rte = "/database/user_rtes/" ~ id ~ "/";
			is_user_route = 1;
		}
		var tree = (secondary ? sec_rte : active_rte);
		if(!secondary)
			me.clear_active();
		else 
			me.clear_sec();

		if(!is_user_route){
			for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
				var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
				if (rte_id == id) {
					var route = co_tree~ "route[" ~ index ~ "]/route/";
					for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
						setprop(tree~ "route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
						if (getprop(route~ "wp[" ~ wp ~ "]/altitude-ft") != nil)
							setprop(tree~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop(route~ "wp[" ~ wp ~ "]/altitude-ft"));
						else {
							# Use CRZ FL
							#setprop(tree~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop("/flight-management/crz_fl") * 100);
							setprop(tree~ "route/wp[" ~ wp ~ "]/altitude-ft", 0);
						}
						if (getprop(route~ "wp[" ~ wp ~ "]/ias-mach") != nil)
							setprop(tree~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(route~ "wp[" ~ wp ~ "]/ias-mach"));
						else {
							var spd = 0;
							# Use 250 kts if under FL100 and 0.78 mach if over FL100

							# if (alt <= 10000)
							#	spd = 250;
							# else
							#	spd = 0.78;
							setprop(tree~ "route/wp[" ~ wp ~ "]/ias-mach", spd);
						}
						# While using the FMGS to fly, if altitude or ias-mach is 0, then the FMGS predicts appropriate values between the previous and next values. If none of the values are entered, the FMGS leaves out that specific control to ALT HOLD or IAS/MACH HOLD

					} # End of WP-Copy For Loop
				} # End of Route ID Check
			} # End of Route-ID For Loop
		} else {
			var fm_route = 'flight-management/';
			if(secondary)
				fm_route ~= 'secondary-rte/';
			var route = user_rte ~ 'route/';
			var fltnum = getprop(user_rte~"flight-num");
			if(fltnum != nil and size(fltnum) > 0)
				setprop(tree~"flight-num", fltnum);
			var crz_fl = getprop(user_rte~"crz_fl");
			if(crz_fl != nil){
				setprop(fm_route~ 'crz_fl', crz_fl);
				if(!secondary){
					var fl_lvl = int(crz_fl) * 100;
					setprop("autopilot/route-manager/cruise/altitude-ft", fl_lvl); 
				}
			}

			for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				setprop(tree~ "route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
				if (getprop(route~ "wp[" ~ wp ~ "]/altitude-ft") != nil)
					setprop(tree~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop(route~ "wp[" ~ wp ~ "]/altitude-ft"));
				else {
					# Use CRZ FL
					#setprop(tree~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop("/flight-management/crz_fl") * 100);
					setprop(tree~ "route/wp[" ~ wp ~ "]/altitude-ft", 0);
				}
				if (getprop(route~ "wp[" ~ wp ~ "]/ias-mach") != nil)
					setprop(tree~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(route~ "wp[" ~ wp ~ "]/ias-mach"));
				else {

					var spd = 0;

					# Use 250 kts if under FL100 and 0.78 mach if over FL100

					# if (alt <= 10000)
					#	spd = 250;
					# else
					#	spd = 0.78;

					setprop(tree~ "route/wp[" ~ wp ~ "]/ias-mach", spd);

				}

				# While using the FMGS to fly, if altitude or ias-mach is 0, then the FMGS predicts appropriate values between the previous and next values. If none of the values are entered, the FMGS leaves out that specific control to ALT HOLD or IAS/MACH HOLD

			} # End of WP-Copy For Loop
		}
	
	},
	
	flt_num : func (mcdu, flight_num) {
	
		var flt_num_rte = 0;
		
		var results = "/instrumentation/mcdu[" ~ mcdu ~ "]/flt-num-results/";
	
################################################################################	
	
		# Come back later (Requires separate Database but it's basically just
		# search for flight number, get dep and arr and then go to dep-arr 
		# results page.)
		
################################################################################
		
		setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/page", "FLT-NUM_RESULTS");
	
	},
	
	from_to : func (mcdu, from, to, secondary = 0) {
	
		var from_to_rte = 0;
		
		var results = "/instrumentation/mcdu[" ~mcdu~ "]/from-to-results/";
		
		setprop(results~ "selected", 0);
	        
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/depicao") != nil; index += 1) {
		
			var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
			
			var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
			
			if ((from == dep) and (to == arr)) {
			
				setprop(results~ "result[" ~ from_to_rte ~ "]/rte_id", getprop(co_tree~ "route[" ~ index ~ "]/rte_id"));
				
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				var rteNode = props.globals.getNode(results~ "result[" ~ from_to_rte ~ "]/route");
				if(rteNode != nil) rteNode.remove();
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
					setprop(results~ "result[" ~ from_to_rte ~ "]/route/wp[" ~ wp ~ "]/wp-id", 
							getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
				
				} # End of Waypoints Copy Loop

				from_to_rte += 1; # From To value increments as index

			} # End of From-To Check
		
		} # End of From-To Loop
		
		
		############ IF CO RTE DOES NOT EXIST  TRIES USER ROUTES ###############
		if (from_to_rte == 0) {
			var user_rtes = "/database/user_rtes_list/";
			for (var index = 0; getprop(user_rtes ~ "name[" ~ index ~ "]") != nil; index += 1) {
				var user_rte_name = getprop(user_rtes ~ "name[" ~ index ~ "]");
				var user_rte = "/database/user_rtes/" ~ user_rte_name ~ "/";
				var dep = getprop(user_rte ~ "depicao");
				if(dep == nil) continue;
				var arr = getprop(user_rte ~ "arricao");
				if ((from == dep) and (to == arr)) {
					#setprop(results~ "result[" ~ from_to_rte ~ "]", '');
					setprop(results~ "result[" ~ from_to_rte ~ "]/rte_id", 'user:' ~ user_rte_name);
					var route = user_rte ~ "route/";
					var rteNode = props.globals.getNode(results~ "result[" ~ from_to_rte ~ "]/route");
					if(rteNode != nil) rteNode.remove();
					for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
						
						setprop(results~ "result[" ~ from_to_rte ~ "]/route/wp[" ~ wp ~ "]/wp-id", 
								getprop(route~ "wp[" ~ wp ~ "]/wp-id"));

					} # End of Waypoints Copy Loop

					from_to_rte += 1; # From To value increments as index
				}

			}
		}
		############ IF CO RTE DOES NOT EXIST ##################################
		if (from_to_rte == 0) {
			setprop(results~ "result", '');
			var rteNode = props.globals.getNode(results~ "result/route");
			if(rteNode != nil) rteNode.remove();
		
			setprop(results~ "result/rte_id", from ~ "/" ~ to);
			
			setprop(results~ "result/route/wp/wp-id", "CO-RTE NOT AVAILABLE, INIT EMPTY F-PLN?");
			
			setprop(results~ "empty-dep", from);
			
			setprop(results~ "empty-arr", to);
			
			setprop(results~ "empty", 1);
			
			from_to_rte == 1;
		
		} else {
		
			setprop(results~ "empty", 0);
		
		}
		
		setprop(results~ "num", from_to_rte);
		setprop(results~ 'secondary-fpln', secondary);
		
		########################################################################
		
		setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/page", "FROM-TO_RESULTS");
		
		me.line_disp();
	
	},
	
	line_disp : func () {
	
		var results = "/instrumentation/mcdu/from-to-results/";	
	
		var select = getprop(results~ "selected");
		
		var select_rte = getprop(results~ "result[" ~ select ~ "]/rte_id");
		
		setprop(results~ "select-id", select_rte);
		
		var line_length = getprop(results~ "line-length");
		
		var num = getprop(results~ "num");
		if(num)
			setprop(results~ "page", (select + 1) ~ "/" ~ num);
		else
			setprop(results~ "page", '');
		
		# Created 1 string out of all waypoints
		
		var rte_string = "";
		
		for (var wp = 0; getprop(results~ "result[" ~ select ~ "]/route/wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
			rte_string = rte_string ~ " " ~ getprop(results~ "result[" ~ select ~ "]/route/wp[" ~ wp ~ "]/wp-id");
				
		}
		
		for(var i = 0; i < 5; i += 1){
			setprop(results~ "lines/line["~i~"]/str", '');
		}
		
		var line1 = substr(rte_string, 0, line_length);
		var line2 = substr(rte_string, line_length, line_length);
		var line3 = substr(rte_string, 2 * line_length, line_length);
		var line4 = substr(rte_string, 3 * line_length, line_length);
		var line5 = substr(rte_string, 4 * line_length, line_length);
		
		# Set lines to property for OSGText XML to read
		
		setprop(results~ "lines/line[0]/str", line1);
		setprop(results~ "lines/line[1]/str", line2);
		setprop(results~ "lines/line[2]/str", line3);
		setprop(results~ "lines/line[3]/str", line4);
		setprop(results~ "lines/line[4]/str", line5);
	
	},
	
	altn_co_rte : func (mcdu, icao, id, secondary = 0) {
		var rm = fmgc.RouteManager;
		var fpID = (secondary ? 'secondary' : nil);
		var fp = rm.getFlightPlan(fpID);
		var fp_dest = fp.destination;
		if(fp_dest == nil) return;
		if(fp == nil) return;
		var alt_fp = rm.setAlternateDestination(icao, fpID);
		if(alt_fp == nil){
			return;
		}
	
		var set_rte = (id != nil and id != '');
		
		if(set_rte){
			var rte_found = 0;
			for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
				var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
				if (rte_id == id) {
					rte_found = 1;
					var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
					var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
					if(arr == icao and dep == fp.departure.id and dep == fp_dest.id) {
						me.altn_rte_sel(id, dep, arr, secondary);
					} else {
						display_message("DEST/ALTN MISMATCH");
					}
					break;
				}
				if(!rte_found)
					display_message(MSG.NOT_IN_DB);
			}
		}
		if(!secondary)
			setprop("flight-management/alternate/icao", icao);
		else 
			setprop("/flight-management/alternate/secondary/icao", icao);
		#f_pln.init_f_pln();
		rm.trigger(rm.SIGNAL_FP_EDIT);
	
	},
	
	altn_rte_sel : func (id, dep, arr, secondary = 0) {
	
		# The Route Select function is the get the selected route and put those stuff into the alternate route
		var tree = (secondary ? sec_altn_rte : altn_rte);
		setprop(tree~ "id", id);
		setprop(tree~ "depicao", dep);
		setprop(tree~ "arricao", arr);
		
		me.set_altn_rte(id, secondary);
	
	},
	
	set_altn_rte : func (id, secondary = 0) {
		var rm = fmgc.RouteManager;
		var tree = (secondary ? sec_altn_rte : altn_rte);
		var fpID = (secondary ? 'secondary' : nil);
		var fp = rm.getAlternateRoute(fpID);
		if(fp == nil) return;
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
	
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
	
			if (rte_id == id) {
			
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
					var wp_id = getprop(route~ "wp[" ~ wp ~ "]/wp-id");
					var wpt = f_pln.create_wp(wp_id);
					if(wpt == nil) continue;
					var real_idx = fp.getPlanSize() - 1;
					fp.insertWP(wpt, real_idx);
					var alt = getprop(route~ "wp[" ~ wp ~ "]/altitude-ft");
					wpt = fp.getWP(real_idx);
					if(alt != nil)
						wpt.setAltitude(alt, 'at');
					var spd = getprop(route~ "wp[" ~ wp ~ "]/ias-mach");
					if(spd != nil)
						wpt.setSpeed(spd, 'at');
					setprop(tree~ "route/wp[" ~ real_idx ~ "]/wp-id", wp_id);
				
				} # End of WP-Copy For Loop
			
			} # End of Route ID Check
	
		} # End of Route-ID For Loop
		
		#f_pln.init_f_pln();
	
	}

};
