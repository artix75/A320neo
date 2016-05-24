var cp_panels = {
       init : func {
            me.UPDATE_INTERVAL = 0.05;
            me.loopid = 0;
            
            me.reset();
    },
    	update : func {
    	
    	gear_pnl.indicators();
		
	},

        reset : func {
            me.loopid += 1;
            me._loop_(me.loopid);
    },
        _loop_ : func(id) {
            id == me.loopid or return;
            utils.catch(func me.update());
            settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
    }

};

setlistener("sim/signals/fdm-initialized", func
 {
 cp_panels.init();
 });
