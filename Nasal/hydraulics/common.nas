var hydraulics = {

	# Hydraulic Pressure values are kept as nasal variables and set into the property tree only after all calculations have been made
	
	common_outputs : ["aileron", "elevator", "rudder", "speedbrake", "flaps"],

	green_psi : 0,
	
	blue_psi : 0,
	
	yellow_psi : 0,

	ptu_apply : func {
		
		var avg_psi = (me.green_psi + me.yellow_psi) / 2;
		
		if (math.abs(me.green_psi - me.yellow_psi) >= 500) {
			setprop('/hydraulics/control/ptu-apply', 1);
			me.green_psi = avg_psi;
			
			me.yellow_psi = avg_psi;
		
		}
	
	},
	
	update_props : func {
	
		setprop("/hydraulics/green/pressure-psi", me.green_psi);
		setprop("/hydraulics/blue/pressure-psi", me.blue_psi);
		setprop("/hydraulics/yellow/pressure-psi", me.yellow_psi);
	
	},
	
	outputs : func {
	
		# If Hydraulic Pressure is available for these in any of the systems, it's serviceable
		
		foreach(var output; me.common_outputs) {
		
			var blue = getprop("hydraulics/outputs/" ~ output ~ "/available-b");
			var green = getprop("hydraulics/outputs/" ~ output ~ "/available-g");
			var yellow = getprop("hydraulics/outputs/" ~ output ~ "/available-y");
			
			if (blue == nil)
				blue = 1;
			
			if (green == nil)
				green = 1;
				
			if (yellow == nil)
				yellow = 1;
				
			if ((blue == 1) or (green == 1) or (yellow == 1)) {
			
				setprop("/sim/failure-manager/controls/flight/" ~ output ~ "/serviceable", 1);
			
			} else {
			
				setprop("/sim/failure-manager/controls/flight/" ~ output ~ "/serviceable", 0);
			
			}
		
		}
	
	}
	
	# Most other functions are hydraulic system specific (green/blue/yellow)

};
