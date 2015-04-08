setprop("/instrumentation/mcdu/load_rtes/first", 0);

var home = getprop("/sim/fg-home");
var active_rte = "/flight-management/active-rte/";

var user = {

	load_rte_list: func() {
		
		io.read_properties(home ~ "/Export/airbus_user_rtes.xml", "/database/user_rtes_list/");
		me.update_disp();
		
	},
	
	load_user_rte: func(name) {
	
		io.read_properties(home ~ "/Export/"~name~".xml", "/database/user_rtes/"~name~"/");
		
		var rte = "/database/user_rtes/"~name~"/";
		
		setprop(active_rte~ "depicao", getprop(rte~"depicao"));
						
		setprop(active_rte~ "arricao", getprop(rte~"arricao"));
		
		setprop(active_rte~ "id", "----------");
        var flight_num = getprop(rte~"flight-num");
        if(flight_num != nil and size(flight_num) > 0)
            setprop(active_rte~"flight-num", flight_num);
        var crz_fl = getprop(rte~'crz_fl');
        if(crz_fl != nil){
            setprop('flight-management/crz_fl', crz_fl);
            var fl_lvl = int(crz_fl) * 100;
            setprop("autopilot/route-manager/cruise/altitude-ft", fl_lvl); 
        }
		
		for (var wp = 0; getprop(rte~ "route/wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
		
			setprop(active_rte~ "route/wp[" ~ wp ~ "]/wp-id", getprop(rte~ "route/wp[" ~ wp ~ "]/wp-id"));
			
			if (getprop(rte~ "route/wp[" ~ wp ~ "]/altitude-ft") != nil)
				setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop(rte~ "route/wp[" ~ wp ~ "]/altitude-ft"));
			else {
			
				# Use CRZ FL
				
				setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop("/flight-management/crz_fl") * 100);
			
			}
			
			if (getprop(rte~ "wp[" ~ wp ~ "]/ias-mach") != nil)
				setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(rte~ "route/wp[" ~ wp ~ "]/ias-mach"));
			else {
			
				var spd = 0;
	
				# Use 250 kts if under FL100 and 0.78 mach if over FL100
		
				# if (alt <= 10000)
				#	spd = 250;
				# else
				#	spd = 0.78;
					
				setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", spd);
	
			}
				
			# While using the FMGS to fly, if altitude or ias-mach is 0, then the FMGS predicts appropriate values between the previous and next values. If none of the values are entered, the FMGS leaves out that specific control to ALT HOLD or IAS/MACH HOLD
		
		} # End of WP-Copy For Loop
		
		f_pln.init_f_pln();

	},
	
	save_user_rte: func(name) {
	
		# Copy Flightplan to active route
		
		me.load_rte_list();
		
		mCDU_init.clear_active();
		
		f_pln.cpy_to_active();
                setprop(active_rte~'crz_fl',getprop('flight-management/crz_fl'));
		
		var filename = home~ "/Export/"~name~".xml";
		
		io.write_properties(filename, active_rte);
				
		var location = "/database/user_rtes_list/";
		
		# Append route to list
		
		var index = 0;
		
		for(var n=0; n < 100; n+=1) {
		
			if (getprop(location~"name["~n~"]") == nil) { 
				index = n;
				break;
			}
		
		}
		
		setprop(location~"name["~index~"]",name);
		
		var rte_list = home~ "/Export/airbus_user_rtes.xml";
	
		io.write_properties(rte_list, location);
	
	},
	
	update_disp: func() {
	
		var first = getprop("/instrumentation/mcdu/load_rtes/first");
		
		for(var n=0; n<5; n+=1) {
		
			var name = getprop("/database/user_rtes_list/name["~n~"]");
			
			if (name != nil) {
			
				setprop("/instrumentation/mcdu/load_rtes/list/name["~n~"]", name);
			
			} else {
			
				setprop("/instrumentation/mcdu/load_rtes/list/name["~n~"]", "");
			
			}
		
		}
	
	}

};

user.load_rte_list();
for(var i = 1; getprop('/database/user_rtes_list/name[' ~ i ~ ']') != nil; i += 1){
    var name = getprop('/database/user_rtes_list/name[' ~ i ~ ']');
    io.read_properties(home ~ "/Export/"~name~".xml", "/database/user_rtes/"~name~"/");    
}
