var hyd_blue = {

	elec_pump : func(lbus, rbus) {
	
		if (lbus + rbus >= 12) {
		
			var out_basic = (lbus + rbus) * 92.68;
		
			if (out_basic > 3000)
				hydraulics.blue_psi = 3000; # Filter
			else
				hydraulics.blue_psi = out_basic;
				
		} else {
		
			hydraulics.blue_psi = 0;
		
		}
	
	},
	
	rat_power : func(airspeed) {
	
		if (airspeed > 110) {
		
			var out_basic = airspeed * 15.625;
			
			if (out_basic > 2500)
				hydraulics.blue_psi = 2500; # Filter
			else
				hydraulics.blue_psi = out_basic;
		
		} else {
		
			hydraulics.blue_psi = 0;
		
		}
	
	},
	
	low_priority_outputs : [], # Slats are controlled with flaps, there isn't a separate output atm
	
	high_priority_outputs : ["hydraulics/outputs/aileron/available-b", "hydraulics/outputs/elevator/available-b", "hydraulics/outputs/rudder/available-b"],
	
	priority_valve : func {
	
		if (hydraulics.blue_psi >= 2000) {
		
			foreach(var lp_output; me.low_priority_outputs) {
			
				setprop(lp_output, 1);
			
			}
		
		} else {
		
			foreach(var lp_output; me.low_priority_outputs) {
			
				setprop(lp_output, 0);
			
			}
		
		}
	
	},
	
	power_outputs : func {
	
		if (hydraulics.blue_psi >= 1000) {
		
			foreach(var hp_output; me.high_priority_outputs) {
			
				setprop(hp_output, 1);
			
			}
		
		} else {
		
			foreach(var hp_output; me.high_priority_outputs) {
			
				setprop(hp_output, 0);
			
			}
		
		}

		me.priority_valve();
	
	}

};
