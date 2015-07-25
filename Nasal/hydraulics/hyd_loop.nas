var hyd_ctrl = "/hydraulics/control/";

var hydraulics_loop = {
       init : func {
            me.UPDATE_INTERVAL = 2;
            me.loopid = 0;
            
            setprop(hyd_ctrl~ "eng1-pump", 1);
            setprop(hyd_ctrl~ "eng2-pump", 1);
            setprop(hyd_ctrl~ "elec-pump", 1);
            setprop(hyd_ctrl~ "ptu", 1);
            
            setprop(hyd_ctrl~ "rat-unlck", 0);
            setprop(hyd_ctrl~ "y-elec-pump", 0);
            
            me.reset();
    },
    	update : func {
    	
    	# Engine Pump (GREEN)
    	
    	if (getprop(hyd_ctrl~ "eng1-pump") == 1)
    		hyd_green.eng1_pump(getprop("/engines/engine/epr"));
    	else
    		hydraulics.green_psi = 0;
    		
    	# Engine and Electric Pumps (YELLOW)
    		
    	if (getprop(hyd_ctrl~ "eng2-pump") == 1)
    		hyd_yellow.eng2_pump(getprop("/engines/engine[1]/epr"));
    	elsif (getprop(hyd_ctrl~ "y-elec-pump") == 1)
    		hyd_yellow.elec_pump(getprop("/systems/electrical/right-bus"));
    	else
    		hydraulics.yellow_psi = 0;
    		
    	# Electric Pumps (BLUE)

		if (getprop(hyd_ctrl~ "elec-pump") == 1)
    		hyd_blue.elec_pump(getprop("/systems/electrical/left-bus"), getprop("/systems/electrical/right-bus"));
    	elsif (getprop(hyd_ctrl~ "rat-unlck") == 1)
    		hyd_blue.rat_power(getprop("/velocities/airspeed-kt"));
    	else
    		hydraulics.blue_psi = 0;  
    	
    	# Some Final Stuff and copy nasal variables to the property tree
    	
    	if (getprop(hyd_ctrl~ "ptu"))    	
    		hydraulics.ptu_apply();
    		
    	if (hydraulics.green_psi > 3000)
    		hydraulics.green_psi = 3000;
    		
    	if (hydraulics.yellow_psi > 3000)
    		hydraulics.yellow_psi = 3000;
    	
    	hydraulics.update_props();
    	
    	# Now, run output calculation and priority valve functions for individual systems
    	
    	## GREEN HYDRAULIC SYSTEM
    	
    	hyd_green.power_outputs();
    	
    	## BLUE HYDRAULIC SYSTEM
    	
    	hyd_blue.power_outputs();
    	
    	## YELLOW HYDRAULIC SYSTEM
    	
    	hyd_yellow.power_outputs();
    	
    	# Hydraulic System Outputs
    	
    	hydraulics.outputs();
		
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
 hydraulics_loop.init();
 print("Airbus Hydraulics System Initialized");
 });
