setprop("/autoland/phase", "disengaged");

var autoland = {

	phase_check: func() {
	
		var agl = getprop("/position/altitude-agl-ft");
		
		var spd = getprop("/velocities/airspeed-kt");
		
		var lbs = getprop("/fdm/jsbsim/inertia/weight-lbs");
		
		var nose_wow = getprop("/gear/gear/wow");
		
		var main_wow = getprop("/gear/gear[3]/wow");
		
		# LAND > FLARE1 > FLARE2 > MAIN_TOUCH (SLOWLY REDUCE PITCH) > NOSE TOUCH (RETARD)
		
		if ((getprop("/flight-management/control/a-thrust") != "off") and (getprop("/flight-management/control/spd-ctrl") == "fmgc") and (getprop("/flight-management/spd-manager/approach/mode") == "MANAGED (AUTO)")) {
		
			if (nose_wow) { 
		
				me.retard();
		
			} elsif (main_wow) {
		
				me.slow(spd);

			} elsif (agl <= 50) {
			
				# setprop("/flight-management/fmgc-values/target-spd", me.spd_manage(lbs) - 30);
				
				setprop("/flight-management/control/a-thrust", "off");
				
				var throttle_l = getprop("/controls/engines/engine[0]/throttle");
				
				var throttle_r = getprop("/controls/engines/engine[1]/throttle");
				
				setprop("/controls/engines/engine[0]/throttle", throttle_l / 2);
				
				setprop("/controls/engines/engine[1]/throttle", throttle_r / 2);

			} elsif (agl <= 100) {

				setprop("/flight-management/fmgc-values/target-spd", me.spd_manage(lbs) - 15);
		
			} else {
		
				setprop("/flight-management/fmgc-values/target-spd", me.spd_manage(lbs));
		
			}
		
		}
		
		if (nose_wow) {
			
			# Exit Autoland
			
			setprop("/autoland/active", 0);
			
			setprop("/flight-management/control/ap1-master", "off");
			
			setprop("/flight-management/control/ap2-master", "off");
			
			setprop("/flight-management/control/a-thrust", "off");
			
			setprop("/autoland/phase", "disengaged");
			
			setprop("/autoland/rudder", 0);
		
		} elsif (main_wow) {
			
			setprop("/autoland/rudder", 1);
			
			setprop("/autoland/phase", "retard");
		
		} elsif (agl <= 20) {
		
			me.flare2(agl);
			
			setprop("/autoland/rudder", 1);
			
			setprop("/autoland/phase", "flare");
		
		} elsif (agl <= 100) {
		
			me.flare1(agl);

			setprop("/autoland/phase", "flare");
			
			setprop("/autoland/rudder", 1);
			
		} 
		
		# Early Descent Approach Scenario as Proposed by Geir
		
		elsif (agl < 1000) {
		
			me.early_descent(spd);
		
		} else {
		
			setprop("/autoland/phase", "land");
			
			setprop("/autoland/rudder", 0);
		
		}
	
	},
	
	spd_manage: func(lbs) {
	
		var spd = 125 + ((lbs - 287000) * 0.000235);
		
		return spd;
	
	},
	
	early_descent : func(spd) {
	
		var trgt_vs = 0.01667 * ((-5 * spd) - 150); # Approx (0,01667 = conv factor for fpm to fps)
		
		setprop("/servo-control/target-vs", trgt_vs);
	
	},
	
	flare1: func(agl) {
	
		if (agl <= 40)	
			setprop("/servo-control/target-vs", -2.5); # -150 fpm
		else
			setprop("/servo-control/target-vs", -5); # -300 fpm
	
	},

	flare2: func(agl) {
	
		# setprop("/servo-control/target-vs", -0.5); Sometimes acts funny
		
		# Using a gradual increase (negative decrease) in target vertical speed, using about -100 fpm at 50 ft and -8 fpm on touchdown (result in feet per second)
		
		# var trgt_vs = -0.01667 * (8 + (agl - 11) * 2.307); (If f2_alt = 50)
		
		var trgt_vs = -0.01667 * (15 + ((agl - 11) * 3.103));
		
		setprop("/servo-control/target-vs", trgt_vs);
	
	},
	
	retard: func() {
	
		setprop("/controls/engines/engine[0]/throttle", 0);
		setprop("/controls/engines/engine[1]/throttle", 0);
	
	},
	
	slow: func(spd) {
		
		setprop("/controls/engines/engine[0]/throttle", 0.1);
				
		setprop("/controls/engines/engine[1]/throttle", 0.1);
	
	}

};
