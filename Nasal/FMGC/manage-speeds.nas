var spd_tree = "/flight-management/spd-manager/";

var manage_speeds = func() {

	# Climb Speeds MANAGED (PERF)
	
	var alt = getprop("/position/altitude-ft");
	
	if ((getprop("/flight-management/phase") == "CLB") and (getprop(spd_tree~ "climb/mode") == "MANAGED (PERF)")) {
		
		if (alt < 14000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "climb/spd1"));
		} elsif (alt < 26000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "climb/spd2"));
		} else {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "climb/mach"));
		}
	
	}
	
	# Cruise Speeds MANAGED (PERF)
	
	elsif ((getprop("/flight-management/phase") == "CRZ") and (getprop(spd_tree~ "cruise/mode") == "MANAGED (PERF)")) {
	
		setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "cruise/mach"));
	
	}
	
	# Descent Speeds MANAGED (PERF)
	
	elsif ((getprop("/flight-management/phase") == "DES") and (getprop(spd_tree~ "descent/mode") == "MANAGED (PERF)")) {
	
		if (alt < 10000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "descent/spd1"));
		} elsif (alt < 18000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "descent/spd2"));
		} else {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "descent/mach"));
		}
	
	} elsif ((getprop("/flight-management/phase") == "APP") and (getprop(spd_tree~ "approach/mode") == "MANAGED (PERF)")) {
	
		var agl = getprop("/position/altitude-agl-ft");
	
		var main_wow = getprop("/gear/gear[3]/wow");
		
		if (main_wow) {
			setprop("/flight-management/control/a-thrust", "off");		
		} elsif (agl < 3000) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "approach/app-spd"));
		} elsif (agl < 100) {
			setprop("/flight-management/fmgc-values/target-spd", getprop(spd_tree~ "approach/flare-spd"));
		}	
	}

};
