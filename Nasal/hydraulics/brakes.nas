var oldApplyBrake = controls.applyBrakes;
controls.applyBrakes = func(v, which = 0){
    oldApplyBrake(v, which);
    if(getprop("/hydraulics/brakes/autobrake-setting") < 3)
        setprop("/hydraulics/brakes/autobrake-setting", 0);
}
var brakes = {

	# Manual Brakes get hydraulic power supply from crew stepping on brake pedals. Autobrakes get power from yellow hydraulic system. The yellow hydraulic system needs to provide atleast 1400 PSI hydraulic power to get autobrakes to work. An accumulator is used with auto-brakes to maintain constant hydraulic flow.
	
	# BRAKE SYSTEM INDICATOR
	# > Left Brake Press : Pressure applied on left main gear brakes
	# > Right Brake Press : Pressure applied on right main gear brakes
	# > Accumulator Press : Pressure of hydraulic fluid stored in hydraulic accumulator
	
	# The air pressure in accumulator (without any hydraulic fluid) is by defauly, 600 psi. The maximum pressure in there would be 4000 and the optimal pressure zone would be from 2500 to 3500 PSI.
	
	pressurize : func() {
	
		var brake_l = getprop("/controls/gear/brake-left");
		var brake_r = getprop("/controls/gear/brake-right");
		
		setprop("/hydraulics/brakes/pressure-left-psi", brake_l * 3000);
		setprop("/hydraulics/brakes/pressure-right-psi", brake_r * 3000);
		
		# NOTE: Max pressure available from brake pedals = 3000, but for auto-brakes the equation would be brake_x * yellow_hyd_press
	
	},
	
	autobrake : func(setting) { # 0 > OFF, 1 > LOW, 2 > MED, 3 > MAX
	
		var brake_norm = setting * 0.25; # Max Auto-brake at 0.75
		
		var accum_press = 600;
		
		if (hydraulics.yellow_psi > 1600)
			accum_press = hydraulics.yellow_psi - 1200;
		elsif (hydraulics.yellow_psi > 600)
			accum_press = hydraulics.yellow_psi;
			
		setprop("/hydraulics/brakes/accumulator-pressure-psi", accum_press);
		
		if ((setting != 0) and (getprop("/gear/gear/wow"))) {
		
			var airspeed = getprop("/velocities/airspeed-kt");
			
			var throttle = getprop("controls/engines/engine[0]/throttle");
			if (airspeed >= 70 and throttle == 0)
				me.abs_active(brake_norm, brake_norm, hydraulics.yellow_psi);
			#else
			#	setprop("/hydraulics/brakes/autobrake-setting", 0);
		
		}
		
		me.abs_indicate(setting);
	
	},
	
	abs_active : func(brake_l, brake_r, press) {
	
		if (press <= 3000) {
			setprop("/controls/gear/brake-left", brake_l * (press / 3000));
			setprop("/controls/gear/brake-right", brake_r * (press / 3000));
		} else {
			setprop("/controls/gear/brake-left", brake_l);
			setprop("/controls/gear/brake-right", brake_r);
		}
		
		setprop("/hydraulics/brakes/pressure-left-psi", brake_l * press);
		setprop("/hydraulics/brakes/pressure-right-psi", brake_r * press);
	
	},
	
	abs_indicate : func(setting) {
	
		var airspeed = getprop("/velocities/airspeed-kt");
		var throttle = getprop("controls/engines/engine[0]/throttle");
	
		if (setting == 0) {
			setprop("/hydraulics/brakes/indicator/low", 0);
			setprop("/hydraulics/brakes/indicator/med", 0);
			setprop("/hydraulics/brakes/indicator/max", 0);
			setprop("/hydraulics/brakes/indicator/low-dec", 0);
			setprop("/hydraulics/brakes/indicator/med-dec", 0);
			setprop("/hydraulics/brakes/indicator/max-dec", 0);
		} elsif (setting == 1) {
			setprop("/hydraulics/brakes/indicator/low", 1);
			setprop("/hydraulics/brakes/indicator/med", 0);
			setprop("/hydraulics/brakes/indicator/max", 0);
			if (getprop("/gear/gear/wow") and (airspeed > 60) and throttle == 0) {
				setprop("/hydraulics/brakes/indicator/low-dec", 1);
				setprop("/hydraulics/brakes/indicator/med-dec", 0);
				setprop("/hydraulics/brakes/indicator/max-dec", 0);
			} else {
				setprop("/hydraulics/brakes/indicator/low-dec", 0);
				setprop("/hydraulics/brakes/indicator/med-dec", 0);
				setprop("/hydraulics/brakes/indicator/max-dec", 0);
			}
		} elsif (setting == 2) {
			setprop("/hydraulics/brakes/indicator/low", 0);
			setprop("/hydraulics/brakes/indicator/med", 1);
			setprop("/hydraulics/brakes/indicator/max", 0);
			if (getprop("/gear/gear/wow") and (airspeed > 60) and throttle == 0) {
				setprop("/hydraulics/brakes/indicator/low-dec", 0);
				setprop("/hydraulics/brakes/indicator/med-dec", 1);
				setprop("/hydraulics/brakes/indicator/max-dec", 0);
			} else {
				setprop("/hydraulics/brakes/indicator/low-dec", 0);
				setprop("/hydraulics/brakes/indicator/med-dec", 0);
				setprop("/hydraulics/brakes/indicator/max-dec", 0);
			}
		} else {
			setprop("/hydraulics/brakes/indicator/low", 0);
			setprop("/hydraulics/brakes/indicator/med", 0);
			setprop("/hydraulics/brakes/indicator/max", 1);
			if (getprop("/gear/gear/wow") and (airspeed > 60) and throttle == 0) {
				setprop("/hydraulics/brakes/indicator/low-dec", 0);
				setprop("/hydraulics/brakes/indicator/med-dec", 0);
				setprop("/hydraulics/brakes/indicator/max-dec", 1);
			} else {
				setprop("/hydraulics/brakes/indicator/low-dec", 0);
				setprop("/hydraulics/brakes/indicator/med-dec", 0);
				setprop("/hydraulics/brakes/indicator/max-dec", 0);
			}
		}
	
	}

};
