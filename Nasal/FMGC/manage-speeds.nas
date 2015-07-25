var spd_tree = "/flight-management/spd-manager/";

var manage_speeds = func(descent_started, decel_point_passed, vmin, vmax) {

	# Climb Speeds MANAGED (PERF)
	
	var alt = getprop("/position/altitude-ft");
    var use_perf_speed = 0;
	
	if ((getprop("/flight-management/phase") == "CLB") and (getprop(spd_tree~ "climb/mode") == "MANAGED (PERF)")) {
		
		if (alt < 14000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "climb/spd1"));
		} elsif (alt < 26000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "climb/spd2"));
		} else {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "climb/mach"));
		}
        use_perf_speed = 1;
	
	}
	
	# Cruise Speeds MANAGED (PERF)
	
	elsif ((getprop("/flight-management/phase") == "CRZ") and (getprop(spd_tree~ "cruise/mode") == "MANAGED (PERF)")) {
	
		setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "cruise/mach"));
        use_perf_speed = 1;
	}
	
	# Descent Speeds MANAGED (PERF)
	
    elsif (!decel_point_passed and (getprop("/flight-management/phase") == "DES") and 
           (getprop(spd_tree~ "descent/mode") == "MANAGED (PERF)") and 
            descent_started) {
	
		if (alt < 10000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "descent/spd1"));
		} elsif (alt < 18000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "descent/spd2"));
		} else {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "descent/mach"));
		}
        use_perf_speed = 1;
	
    } elsif (((getprop("/flight-management/phase") == "APP") or decel_point_passed) and 
             (getprop(spd_tree~ "approach/mode") == "MANAGED (PERF)")) {
	
		var agl = getprop("/position/altitude-agl-ft");
	
		var main_wow = getprop("/gear/gear[2]/wow");
		
		if (main_wow) {
			setprop("/flight-management/control/a-thrust", "off");		
        } elsif (agl < 3000 or decel_point_passed) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "approach/app-spd"));
		} elsif (agl < 100) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "approach/flare-spd"));
		}
        use_perf_speed = 1;
	}

    if(use_perf_speed and vmax and getprop("/flight-management/fmgc-values/target-spd") > vmax)
        setprop("/flight-management/fmgc-values/target-spd", vmax);
    elsif(use_perf_speed and vmin and getprop("/flight-management/fmgc-values/target-spd") < vmin)
        setprop("/flight-management/fmgc-values/target-spd", vmin);
};
