# MCDU RADIO NAVIGATION PAGE ###################################################

var radio = "/flight-management/freq/";

var nav1 = "/instrumentation/nav[0]/";

var nav2 = "/instrumentation/nav[1]/";

setprop(radio~ "ils-mode", 0); # ILS Mode for NAV1
setprop(radio~ "mls-mode", 0); # MLS Mode for NAV2

setprop(radio~ "ils", 0); # %3.2f number values
setprop(radio~ "ils-crs", 0);
setprop(radio~ "mls", 0);
setprop(radio~ "mls-crs", 0);
setprop(radio~ "vor1", 0);
setprop(radio~ "vor1-crs", 0);
setprop(radio~ "vor2", 0);
setprop(radio~ "vor2-crs", 0);

# Navigation IDs

setprop(radio~ "vor1-id", "---");
setprop(radio~ "vor2-id", "---");
setprop(radio~ "ils-id", "---");
setprop(radio~ "mls-id", "---");

var rad_nav = {

	switch_nav1 : func(ils) {
	
		if (ils == 1) {
		
			setprop(nav1~ "frequencies/selected-mhz", getprop(radio~ "ils"));
			
			setprop(nav1~ "radials/selected-deg", getprop(radio~ "ils-crs"));
		
		} else {
		
			setprop(nav1~ "frequencies/selected-mhz", getprop(radio~ "vor1"));
			
			setprop(nav1~ "radials/selected-deg", getprop(radio~ "vor1-crs"));
		
		}
	
	},
	
	switch_nav2 : func(mls) {
	
		if (mls == 1) {
		
			setprop(nav2~ "frequencies/selected-mhz", getprop(radio~ "mls"));
			
			setprop(nav2~ "radials/selected-deg", getprop(radio~ "mls-crs"));
		
		} else {
		
			setprop(nav2~ "frequencies/selected-mhz", getprop(radio~ "vor2"));
			
			setprop(nav2~ "radials/selected-deg", getprop(radio~ "vor2-crs"));
		
		}
	
	},
	
	search_vor : func(id) {
	
		var gps = "/instrumentation/gps/";
		
		setprop(gps~ "scratch/query", id);
		
		setprop(gps~ "scratch/type", "vor");
		
		setprop(gps~ "command", "search");
		
		var freq = getprop(gps~ "scratch/frequency-mhz");
		
		return freq;
	
	}

};
