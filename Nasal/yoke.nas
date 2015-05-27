var arduyoke = {
       init : func {
            me.UPDATE_INTERVAL = 0.01;
            me.loopid = 0;
            
            me.reset();
    },
    	update : func {
		
		if(getprop("/arduino/input/rudder") != nil) {
			setprop("/controls/flight/rudder", getprop("/arduino/input/rudder")*math.abs(getprop("/arduino/input/rudder"))*1.5);
		}
		
		setprop("/controls/engines/engine[1]/throttle", getprop("/controls/engines/engine/throttle"));
		
		setprop("/controls/gear/brake-left", getprop("/arduino/input/switches/brakes")/2);
		
		setprop("/controls/gear/brake-right", getprop("/arduino/input/switches/brakes")/2);
    	
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

setlistener("sim/signals/fdm-initialized", func {
	arduyoke.init();
	print("Initialized ArduCockpit Mega v1.0");
});
