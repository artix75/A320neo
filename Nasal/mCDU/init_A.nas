var co_tree = "/database/co_routes/";
var active_rte = "/flight-management/active-rte/";
var altn_rte = "/flight-management/alternate/route/";

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

setprop("/flight-management/alternate/icao", "empty");
setprop(altn_rte~ "depicao", "empty");
setprop(altn_rte~ "arricao", "empty");

setprop("/flight-management/cost-index", 0);
setprop("/flight-management/crz_fl", 0);

var mCDU_init = {

	co_rte : func (mcdu, id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
		
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
		
			if (rte_id == id) {
			
				var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
				var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
			
				me.rte_sel(id, dep, arr);
			
			} else
				setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/input", "ERROR: NOT IN DATABASE");
		
		}
		
		setprop("/flight-management/end-flight", 0);
		
		f_pln.init_f_pln();
	
	},
	
	rte_sel : func (id, dep, arr) {
	
		# The Route Select function is the get the selected route and put those stuff into the active route
		
		setprop(active_rte~ "id", id);
		setprop(active_rte~ "depicao", dep);
		setprop(active_rte~ "arricao", arr);
		
		me.set_active_rte(id);
	
	},
	
	set_active_rte : func (id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
	
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
	
			if (rte_id == id) {
			
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
					setprop(active_rte~ "route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
					
					if (getprop(route~ "wp[" ~ wp ~ "]/altitude-ft") != nil)
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop(route~ "wp[" ~ wp ~ "]/altitude-ft"));
					else {
					
						# Use CRZ FL
						
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop("/flight-management/crz_fl") * 100);
					
					}
					
					if (getprop(route~ "wp[" ~ wp ~ "]/ias-mach") != nil)
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(route~ "wp[" ~ wp ~ "]/ias-mach"));
					else {
					
						var spd = 0;
			
						# Use 250 kts if under FL100 and 0.78 mach if over FL100
				
						if (alt <= 10000)
							spd = 250;
						else
							spd = 0.78;
							
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", spd);
			
					}
						
					# While using the FMGS to fly, if altitude or ias-mach is 0, then the FMGS predicts appropriate values between the previous and next values. If none of the values are entered, the FMGS leaves out that specific control to ALT HOLD or IAS/MACH HOLD
				
				} # End of WP-Copy For Loop
			
			} # End of Route ID Check
	
		} # End of Route-ID For Loop
	
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
	
	from_to : func (mcdu, from, to) {
	
		var from_to_rte = 0;
		
		var results = "/instrumentation/mcdu[" ~mcdu~ "]/from-to-results/";
		
		setprop(results~ "selected", 0);		
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/depicao") != nil; index += 1) {
		
			var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
			
			var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
			
			if ((from == dep) and (to == arr)) {
			
				setprop(results~ "result[" ~ from_to_rte ~ "]/rte_id", getprop(co_tree~ "route[" ~ index ~ "]/rte_id"));
				
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
					setprop(results~ "result[" ~ from_to_rte ~ "]/route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
				
				} # End of Waypoints Copy Loop

				from_to_rte += 1; # From To value increments as index

			} # End of From-To Check
		
		} # End of From-To Loop
		
		############ IF CO RTE DOES NOT EXIST ##################################
		
		if (from_to_rte == 0) {
		
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
		
		setprop(results~ "page", (select + 1) ~ "/" ~ num);
		
		# Created 1 string out of all waypoints
		
		var rte_string = "";
		
		for (var wp = 0; getprop(results~ "result[" ~ select ~ "]/route/wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
			rte_string = rte_string ~ " " ~ getprop(results~ "result[" ~ select ~ "]/route/wp[" ~ wp ~ "]/wp-id");
				
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
	
	altn_co_rte : func (mcdu, icao, id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
		
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
		
			if (rte_id == id) {
			
				var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
				var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
			
				me.altn_rte_sel(id, dep, arr);
			
			} else
				setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/input", "ERROR: NOT IN DATABASE");
		
		}
		
		setprop("flight-management/alternate/icao", icao);
	
	},
	
	altn_rte_sel : func (id, dep, arr) {
	
		# The Route Select function is the get the selected route and put those stuff into the alternate route
		
		setprop(altn_rte~ "id", id);
		setprop(altn_rte~ "depicao", dep);
		setprop(altn_rte~ "arricao", arr);
		
		me.set_altn_rte(id);
	
	},
	
	set_altn_rte : func (id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
	
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
	
			if (rte_id == id) {
			
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
					setprop(altn_rte~ "route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
					
					if (getprop(route~ "wp[" ~ wp ~ "]/altitude-ft") != nil)
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop(route~ "wp[" ~ wp ~ "]/altitude-ft"));
					else {
					
						# Use CRZ FL
						
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop("/flight-management/crz_fl") * 100);
					
					}
					
					if (getprop(route~ "wp[" ~ wp ~ "]/ias-mach") != nil)
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(route~ "wp[" ~ wp ~ "]/ias-mach"));
					else {
					
						var spd = 0;
			
						# Use 250 kts if under FL100 and 0.78 mach if over FL100
				
						if (alt <= 10000)
							spd = 250;
						else
							spd = 0.78;
							
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", spd);
			
					}
				
				} # End of WP-Copy For Loop
			
			} # End of Route ID Check
	
		} # End of Route-ID For Loop
	
	}

};
