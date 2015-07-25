var brakes_loop = {
       init : func {
            me.UPDATE_INTERVAL = 0.05;
            me.loopid = 0;
            
            setprop("/hydraulics/brakes/autobrake-setting", 0);
            
            me.reset();
    },
    	update : func {
    	
    	################ BRAKE SYSTEM ################
    	
    	# Manual Brakes Pressure
    	
    	brakes.pressurize();
    	
    	# Auto Braking System (And accumulator pressure)
    	
    	brakes.autobrake(getprop("/hydraulics/brakes/autobrake-setting"));
		
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
 brakes_loop.init();
 print("Automatic Brakes System Initialized");
 });
