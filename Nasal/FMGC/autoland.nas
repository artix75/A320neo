setprop("/autoland/phase", "disengaged");
setprop("/autoland/retard", 0);
setprop("/autoland/early-descent", 400);

var autoland = {

	phase_check: func() {
	
		var agl = getprop("/position/altitude-agl-ft");
		
		var spd = getprop("/velocities/airspeed-kt");
		
		var lbs = getprop("/fdm/jsbsim/inertia/weight-lbs");
		
		var nose_wow = getprop("/gear/gear/wow");
		
		var main_wow = getprop("/gear/gear[2]/wow");
        var athr = getprop("/flight-management/control/a-thrust");
        
        #print("Autoland phase check");
		
		# LAND > FLARE1 > FLARE2 > MAIN_TOUCH (SLOWLY REDUCE PITCH) > NOSE TOUCH (RETARD)
		
		if ((athr == "eng") and 
			(getprop("/flight-management/control/spd-ctrl") == "fmgc")) {
		    #print("Autoland speed management");
			if (nose_wow or main_wow or agl <= 50) { 
				me.retard();
			} 
			elsif (agl <= 100) {
                #print("Autoland: AGL <= 100, regulating speed and activating autoland");

				setprop("/flight-management/fmgc-values/target-spd", me.spd_manage(lbs) - 15);
			    setprop("/autoland/active", 1);
                setprop("/autoland/retard", 0);
                
		
			} else {
                #print("Autoland: regulating speed and activating autoland");
				setprop("/flight-management/fmgc-values/target-spd", me.spd_manage(lbs));
                setprop("/autoland/retard", 0);
			}
		
		}
		
		if (getprop("/velocities/airspeed-kt") <= 70) {
            #print("Autoland: IAS <= 70, deactivating autoland and AP");
			setprop("/autoland/active", 0);
			
			setprop("/autoland/phase", "disengaged");
			
			setprop("/flight-management/control/ap1-master", "off");
			
			setprop("/flight-management/control/ap2-master", "off");
		
		} elsif (nose_wow) {
            #print("Autoland: nose touch down, deactivating ATHR, activating rollout");
			#setprop("/flight-management/control/a-thrust", "off");
			
			setprop("/autoland/phase", "rollout");
			
			setprop("/autoland/rudder", 1);
            #setprop("/autoland/retard", 0);
		
		} elsif (main_wow) {
            #print("Autoland: main touch down, target-vs -10 and rollout");
            setprop("/servo-control/target-vs", -10);
			setprop("/autoland/rudder", 1);
			
			setprop("/autoland/phase", "rollout");
		
		} elsif (agl <= 25) {
            #print("Autoland: AGL <= 25, flare2");
		
			me.flare2(agl);
			
			setprop("/autoland/rudder", 1);
			
			setprop("/autoland/phase", "flare");
		
		} elsif (agl <= 50) {
            #print("Autoland: AGL <= 50, flare1");
		
			me.flare1(agl);

			setprop("/autoland/phase", "flare");
			
			setprop("/autoland/rudder", 1);
            if (athr == "eng")
                me.retard();
			
		} 
		
		# Early Descent Approach Scenario as Proposed by Geir
		
		elsif (agl < getprop("/autoland/early-descent")) {
            #print("Autoland: early descent");
		
			me.early_descent(spd);
            setprop("/autoland/retard", 0);
		
		} else {
            #print("Autoland: no rudder");
		
			setprop("/autoland/phase", "land");
			
			setprop("/autoland/rudder", 0);
            setprop("/autoland/retard", 0);
		
		}
	
	},
	
	spd_manage: func(lbs) {
		var spd = getprop('/flight-management/spd-manager/approach/app-spd');
		if(spd) return spd;
		var rwy = flightplan().destination_runway;
		if(rwy != nil){
			var magwind = getprop('/flight-management/settings/mag-wind');
			if(magwind != nil and find('/', magwind) >= 0){
				var wind_spd = me.calc_runway_wind(rwy, magwind);
				var vapp = me.calc_vapp(rwy, wind_spd);
				var gust = 0;
				var head_wind = aircraft.wind_speed_from(fmgc_loop.heading);
				var wnd_diff = head_wind - wind_spd;
				if(wnd_diff < 0) wnd_diff = 0;
				if(fmgc_loop.agl > 400){
					gust = wnd_diff;
				} else {
					gust = int(wnd_diff / 3);
				}
				spd = vapp + gust;
				if(spd < vapp) spd = vapp;
				return spd;
			}
		}
		spd = 125 + ((lbs - 287000) * 0.000235);
		setprop('flight-management/fmgc-values/vapp', spd);
		return spd;
	
	},
	calc_vapp: func(runway, wind_spd){
		if(wind_spd < 0) wind_spd = 0;
		if(wind_spd > 15) wind_spd = 15;
		var vls = fmgc_loop.appr_vls or 135;
		var base_vapp = vls + 5;
		var vapp = vls + int(wind_spd / 3);
		vapp = (vapp > base_vapp ? vapp : base_vapp);
		setprop('flight-management/fmgc-values/vapp', vapp);
		return vapp;
	},
	calc_runway_wind: func(runway, tower_wind){
		if(runway == nil) return 0;
		var hdg = runway.heading;
		var wind_info = split('/', tower_wind);
		if(!size(wind_info)) return 0;
		var wind_dir = num(wind_info[0]);
		if(wind_dir == nil) wind_dir = 0;
		var wind_spd = 0;
		if(size(wind_info) > 1)
		wind_spd = num(wind_info[1]);
		if(wind_spd == nil) wind_spd = 0;
		var dir = (wind_dir - hdg) * D2R;
		return wind_spd * math.cos(dir);
	},
	early_descent : func(spd) {
	
		var trgt_vs = 0.01667 * ((-5 * spd) - 150); # Approx (0,01667 = conv factor for fpm to fps)
		
		setprop("/servo-control/target-vs", trgt_vs);
	
	},
	
	flare1: func(agl) {
	
		if (agl <= 30)
			setprop("/servo-control/target-vs", -2.5); # -150 fpm
		else
			setprop("/servo-control/target-vs", -5); # -300 fpm
	
	},

	flare2: func(agl) {
	
		# setprop("/servo-control/target-vs", -0.5); Sometimes acts funny
		
		# Using a gradual increase (negative decrease) in target vertical speed, using about -100 fpm at 50 ft and -8 fpm on touchdown (result in feet per second)
		
		# var trgt_vs = -0.01667 * (8 + (agl - 11) * 2.307); (If f2_alt = 50)
		
		var trgt_vs = -0.01667 * (15 + ((agl - 11) * 3.103));
        if(trgt_vs > -2.3)
            trgt_vs = -2.3;
		
		setprop("/servo-control/target-vs", trgt_vs);
	
	},
	
	retard: func() {
        setprop("/autoland/retard", 1);
	},
	
	slow: func(spd) {
		setprop("/flight-management/fmgc-values/target-spd", 60);
	
	}

};
