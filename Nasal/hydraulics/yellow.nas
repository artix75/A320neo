var hyd_yellow = {

	eng2_pump : func(epr) {
	
		var out_basic = 0;
		
		if (epr > 1)		
			out_basic = epr * 2400;
		
		if (out_basic > 6000)
			hydraulics.yellow_psi = 6000; # Filter
		else
			hydraulics.yellow_psi = out_basic;
	
	},
	
	elec_pump : func(rbus) {
	
		if (rbus >= 12) {
		
			var out_basic = (2 * rbus) * 108.33;
		
			if (out_basic > 3000)
				hydraulics.yellow_psi = 3000; # Filter
			else
				hydraulics.yellow_psi = out_basic;
				
		} else {
		
			hydraulics.yellow_psi = 0;
		
		}
	
	},
	
	low_priority_outputs : ["hydraulics/outputs/flaps/available-y"],
	
	high_priority_outputs : ["hydraulics/outputs/aileron/available-y", "hydraulics/outputs/elevator/available-y", "hydraulics/outputs/rudder/available-y", "hydraulics/outputs/speedbrake/available-y"],
	
	priority_valve : func {
	
		if (hydraulics.yellow_psi >= 2400) {
		
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
	
		if (hydraulics.yellow_psi >= 1200) {
		
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
