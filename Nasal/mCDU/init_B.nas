# INIT B (FUEL PREDICTION) SECTION ON mCDU

# NOTE : Fuel is entered and calculated in 'blocks' - 1 block is approximately 1000 L.
# To convert KG to Blocks, BLOCKS = KG / 804 (JET A FUEL DENSTY = 0.804 kg/L)

# Initialize Variables

var fuel = "/instrumentation/mcdu/fuel/";
var fuel_disp = "/instrumentation/mcdu/fuel/disp/";

setprop(fuel~ "taxi", 0.2);
setprop(fuel~ "rte-rsv", 0);
setprop(fuel~ "rsv-100", 0);
setprop(fuel~ "final-f", 4);
setprop(fuel~ "final-t", 45);
setprop(fuel~ "zfw", 264.0);
setprop(fuel~ "zfw-cg", 22.5);

# Initialize Display Texts

setprop(fuel_disp~ "rsv", "--.-/--.-");
setprop(fuel_disp~ "fin", "4.0/0045");
setprop(fuel_disp~ "blk", 0);

var init_B = {

	zfw : func {
	
		var zfw = getprop(fuel~ "zfw");
		
		var zfw_cg = getprop(fuel~ "zfw-cg");
		
		# Get First decimal place
		
		var dec_zfw = int((zfw - int(zfw)) * 10);
		
		var dec_zfw_cg = int((zfw_cg - int(zfw_cg)) * 10);
	
		setprop(fuel_disp~ "zfw", int(zfw) ~ "." ~ dec_zfw ~ "/" ~ int(zfw_cg) ~ "." ~ dec_zfw_cg);
	
	},

	trip : func {
	
		var trip_time = getprop("/instrumentation/mcdu/f-pln/disp/time");
		
		# MILEAGE = (approx for trip time) 0.0523 Blocks per min
		
		var trip_fuel = trip_time * 0.124;
		
		setprop(fuel~ "trip-fuel", trip_fuel);
		
		setprop(fuel_disp~ "trp", int(trip_fuel) ~ "/" ~ trip_time);
		
	},
	
	dest : func {
		
		setprop(fuel_disp~ "fob", getprop(fuel~ "final-f"));
	
	},
	
	extra : func {
	
		var fob = getprop(fuel_disp~ "blk");
		
		if ((fob != 0) and (fob != nil)) {
		
			var trip = getprop(fuel~ "trip-fuel");
			
			var final = getprop(fuel~ "final-f", 4);
			
			var rsv = getprop(fuel~ "rte-rsv");
		
			if (trip == nil)
				trip = 0;
			
			if (final == nil)
				final = 0;
				
			if (rsv == nil)
				rsv = 0;
		
			var extra = fob - (trip + final + rsv);
			
			# Time is calculated considering racetrack pattern
			
			var extra_time = extra * 8.46; # Minutes avail with 1 block fuel
			
			var extra_dec = int((extra - int(extra))*10);
			
			setprop(fuel~ "extra", extra);
			
			setprop(fuel_disp~ "ext", int(extra) ~ "." ~ extra_dec ~ "/" ~ me.time_str(extra_time));
		
		} else {
		
			setprop(fuel~ "extra", 0);
		
			setprop(fuel_disp~ "ext", "-.-/----");
		
		}
	
	},
	
	tow_lw : func {
	
		var zfw = getprop(fuel~ "zfw");
		
		var block = getprop(fuel_disp~ "blk");
		
		var extra = getprop(fuel~ "extra");
		
		if ((block != 0) and (extra != 0)) {
		
			var tow = zfw + ((2.2046 * block * 804)/1000);
		
			var lw = zfw + ((2.2046 * extra * 804)/1000);
			
			var tow_dec = int((tow - int(tow)) * 10);
			
			var lw_dec = int((lw - int(lw)) * 10);
			
			setprop(fuel_disp~ "tow", int(tow) ~ "." ~ tow_dec ~ "/" ~ int(lw) ~ "." ~ lw_dec);
			
		} else {
		
			setprop(fuel_disp~ "tow", "---.-/---.-");
		
		}
	
	},
	
	update : func {
	
		me.trip();
		
		me.dest();
		
		me.extra();
		
		me.tow_lw();
		
		me.zfw();
	
	},
	
	time_str : func(val) {
	
		if (val < 10)
			return "000" ~ int(val);
		elsif (val < 100)
			return "00" ~ int(val);
		elsif (val < 1000)
			return "0" ~ int(val);
		else
			return int(val);
	
	}

};
