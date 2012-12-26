var new = func {
	return {parents:arg};
}

var gear_indicator = {unlk : 0, down : 0};
		
var gears = [new(gear_indicator), new(gear_indicator), new(gear_indicator)];

var gear_pnl = {

	indicators : func() {
	
		for (var gear = 0; gear < 3; gear += 1) {
		
			gears[gear].unlk = 0;
			gears[gear].down = 0;
		
			var pos = getprop("/gear/gear[" ~ gear ~ "]/position-norm");
			
			if (pos != 0) {
			
				gears[gear].unlk = 1;
				
				if (pos == 1)
					gears[gear].down = 1;
			
			}
		
			setprop("/indicators/gear-panel/gear[" ~ gear ~ "]/unlk", gears[gear].unlk);
			setprop("/indicators/gear-panel/gear[" ~ gear ~ "]/down", gears[gear].down);
		
		}
	
	}

};
