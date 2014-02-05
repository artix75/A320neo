# This loop Updates every 10 seconds

var mCDU_loop_10 = {
       init : func {
            me.UPDATE_INTERVAL = 5;
            me.loopid = 0;
            
            setprop("/instrumentation/mcdu/f-pln/disp/first", 0);
            
            me.reset();
    },
       update : func {

    	# Position String
    	
    	setprop("/instrumentation/mcdu/pos-string", getprop("/position/latitude-string") ~ "/" ~ getprop("/position/longitude-string"));
    	
    	# Always start at the 'start' page and have f-pln start at beginning
    	
    	if (getprop("/instrumentation/mcdu/brt") == 0) {
    		setprop("/instrumentation/mcdu/page", "start");
    		setprop("/instrumentation/mcdu/f-pln/disp/first", 0);
    	}
    	
    	var rte_dist = getprop(rm_route~ "wp-last/dist");
    	
    	if (rte_dist != nil)
			setprop(f_pln_disp~ "dist", int(rte_dist));
		else
			setprop(f_pln_disp~ "dist", "----");
			
		# Radio NAV ID Loop
		
		var ils = getprop("/flight-management/freq/ils-mode");
		
		var mls = getprop("/flight-management/freq/mls-mode");
		
		var nav1_id = getprop("/instrumentation/nav/nav-id");
		
		var nav2_id = getprop("/instrumentation/nav[1]/nav-id");
		
		if (nav1_id == nil)
			nav1_id = "---";
			
		if (nav2_id == nil)
			nav2_id = "---";
		
		if (ils) {
		
			setprop("/flight-management/freq/vor1-id", "---");
			
			setprop("/flight-management/freq/ils-id", nav1_id);
		
		} else {
		
			setprop("/flight-management/freq/ils-id", "---");
			
			setprop("/flight-management/freq/vor1-id", nav1_id);
		
		}
		
		if (mls) {
		
			setprop("/flight-management/freq/vor2-id", "---");
			
			setprop("/flight-management/freq/mls-id", nav2_id);
		
		} else {
		
			setprop("/flight-management/freq/mls-id", "---");
			
			setprop("/flight-management/freq/vor2-id", nav2_id);
		
		}

	},
        reset : func {
            me.loopid += 1;
            me._loop_(me.loopid);
    },
        _loop_ : func(id) {
            id == me.loopid or return;
            me.update();
            settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
    }

};


setlistener("sim/signals/fdm-initialized", func
 {
 mCDU_loop_10.init();
 });
