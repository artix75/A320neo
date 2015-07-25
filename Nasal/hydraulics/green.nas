var hyd_green = {

	eng1_pump : func(epr) {
	
		var out_basic = 0;
		
		if (epr > 1)		
			out_basic = epr * 2400;
		
		if (out_basic > 6000)
			hydraulics.green_psi = 6000; # Filter
		else
			hydraulics.green_psi = out_basic;
	
	},
	
	low_priority_outputs : ["hydraulics/outputs/flaps/available-g", "gear/serviceable"],
	
	high_priority_outputs : ["hydraulics/outputs/aileron/available-g", "hydraulics/outputs/elevator/available-g", "hydraulics/outputs/rudder/available-g", "hydraulics/outputs/speedbrake/available-g"],
	
	priority_valve : func {
	
		if (hydraulics.green_psi >= 2400) {
		
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
	
		if (hydraulics.green_psi >= 1200) {
		
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
