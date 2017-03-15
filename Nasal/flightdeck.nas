var fcu = {
    init: func(){
        me.UPDATE_INTERVAL = 0.1;
        me.FCU_DISPLAY_TIMEOUT = 3;
        foreach(var knob; ['spd','hdg','alt','vs']){
            setprop('/flight-management/fcu/'~knob~'-rotation-time',-1); 
            setprop('/flight-management/fcu/display-'~knob, 0); 
        }
        me.update();
    },
    update: func(){
	utils.catch(func() {
            foreach(var knob; ['spd','hdg','alt','vs']){
                var sec = getprop('/flight-management/fcu/'~knob~'-rotation-time');
                if(sec > 0){
                    var cur_sec = int(getprop('sim/time/elapsed-sec'));
                    var elapsed = cur_sec - sec;
                    var disp = (elapsed <= me.FCU_DISPLAY_TIMEOUT);
                    setprop('/flight-management/fcu/display-'~knob, disp);
                } else {
                    setprop('/flight-management/fcu/display-'~knob, 0);
                }
            }
        });
        settimer(func { me.update(); }, me.UPDATE_INTERVAL);
    },
    get_type: func(name){
        var type = '';
        if(name == 'hdg')
            type = 'lat';
        elsif(name == 'spd')
            type = name;
        elsif(name == 'alt')
            type = 'ver';
        return type;
    },
    knob_rotated: func(name){
        utils.clickSound(3);
        var type = me.get_type(name);
        if(type == '') return;
        var mode = getprop('/flight-management/control/' ~ type ~ '-ctrl');
        if(mode == 'fmgc'){
            var sec = int(getprop('sim/time/elapsed-sec'));
            setprop('/flight-management/fcu/'~name~'-rotation-time', sec);
        } else {
            setprop('/flight-management/fcu/'~name~'-rotation-time', -1);
        }
    },
    knob_pushed: func(name){
        utils.clickSound(4);
        me.push_animation(name);
        if (fmgc.fmgc_loop.active_common_mode == 'LAND')
            return;
        var type = me.get_type(name);
        if(type == '') return;
        var mode_prop = '/flight-management/control/' ~ type ~ '-ctrl';
        var mode = getprop(mode_prop);
        if (mode != 'fmgc'){
            setprop(mode_prop, 'fmgc');
        }
        if(name == 'alt'){
            setprop("/flight-management/fcu-values/alt", 
                    getprop("/flight-management/fcu-values/fcu-alt"));
            setprop('/flight-management/control/vsfpa-mode', 0);
            setprop('/flight-management/fcu/display-vs', 0);
        }
    },
    knob_pulled: func(name){
        utils.clickSound(4);
        me.pull_animation(name);
        if (fmgc.fmgc_loop.active_common_mode == 'LAND')
            return;
        var type = me.get_type(name);
        if(type == '') return;
        var mode_prop = '/flight-management/control/' ~ type ~ '-ctrl';
        var mode = getprop(mode_prop);
        if (mode != 'man-set'){
            setprop(mode_prop, 'man-set');
        }
        if(name == 'alt'){
            setprop("/flight-management/fcu-values/alt", 
                    getprop("/flight-management/fcu-values/fcu-alt"));
            setprop('/flight-management/control/vsfpa-mode', 0);
            setprop('/flight-management/fcu/display-vs', 0);
        }
        elsif(name == 'hdg'){
            setprop('autopilot/settings/heading-bug-deg', 
                    getprop("/flight-management/fcu-values/hdg"));
        }
    },
    push_animation: func(name){
        var pos_prop = 'flightdeck/fcu/'~name~'-knob-pos';
        var knob_pos = getprop(pos_prop);
        if(knob_pos == nil) knob_pos = 0;
        if(knob_pos <= 0){
            interpolate(pos_prop, 1, 0.1);
            settimer(func setprop(pos_prop, 0), 0.11);
        }
    },
    pull_animation: func(name){
        var pos_prop = 'flightdeck/fcu/'~name~'-knob-pos';
        var knob_pos = getprop(pos_prop);
        if(knob_pos == nil) knob_pos = 0;
        if(knob_pos >= 0){
            interpolate(pos_prop, -1, 0.1);
            settimer(func setprop(pos_prop, 0), 0.11);
        }
    },
    vsfpa_rotated: func(){
        utils.clickSound(3);
        var vs_mode = getprop('/flight-management/control/vsfpa-mode');
        if (!vs_mode){
            var sec = int(getprop('sim/time/elapsed-sec'));
            setprop('/flight-management/fcu/vs-rotation-time', sec);
        } else {
            setprop('/flight-management/fcu/vs-rotation-time', -1);
        }
    },
    vsfpa_pushed: func(){
        utils.clickSound(4);
        if (fmgc.fmgc_loop.active_common_mode == 'LAND')
            return;
        setprop("/flight-management/fcu-values/vs", 0);
        setprop("/flight-management/fcu-values/fpa", 0);
        setprop("/flight-management/control/ver-ctrl", "man-set");
        setprop('/flight-management/control/vsfpa-mode', 1);
    },
    vsfpa_pulled: func(){
        utils.clickSound(4);
        if (fmgc.fmgc_loop.active_common_mode == 'LAND')
            return;
        setprop("/flight-management/control/ver-ctrl", "man-set");
        setprop('/flight-management/control/vsfpa-mode', 1);
        setprop("/flight-management/fcu-values/alt", 
                getprop("/flight-management/fcu-values/fcu-alt"));
    },
    alt_rotated: func(direction){
        utils.clickSound(3);
        var step = getprop("/flight-management/control/alt-sel-mode");
        var alt_prop = "/flight-management/fcu-values/alt";
        var alt_disp = "/flight-management/fcu-values/fcu-alt";
        var current_val = getprop(alt_disp);
        var selected_alt = getprop(alt_prop);
        if (direction == 'decr'){
            step *= -1;  
            if (0 >= current_val) return;
        } else {
            if (41000 <= current_val) return;
        };
        var new_alt = current_val + step;
        setprop(alt_disp, new_alt);
        var alt = fmgc.fmgc_loop.altitude;
        var is_alt_mode = (math.abs(alt - selected_alt) <= 250);
        if (!is_alt_mode){
            setprop(alt_prop, new_alt);
            #me.alt_changed(new_alt);
        }
    },
    alt_changed: func(new_alt){
        var crz_fl = getprop("/flight-management/crz_fl");
        var crz_alt = int(crz_fl * 100);
        if(new_alt > crz_alt){
            setprop("/flight-management/crz_fl", int(new_alt / 100));
            setprop("autopilot/route-manager/cruise/altitude-ft", new_alt);
        }
    }
};

var Chrono = {
    new: func(idx, listen_prop=nil){
        var m = {
            parents: [Chrono],
            index: idx
        };
        m.init();
        if(listen_prop != nil)
            m.listen(listen_prop);
        return m;
    },
    init: func(){
        var parentNode = props.globals.getNode('instrumentation');
		var path = 'instrumentation/chrono['~me.index~']';
        me.node = parentNode.getNode(path);
		if(me.node == nil)
			me.node = props.globals.initNode(path);
        path = me.node.getPath();
        props.globals.initNode(path~ '/started', 0, 'BOOL');
        props.globals.initNode(path~ '/paused', 0, 'BOOL');
        props.globals.initNode(path~ '/started-at', 0, 'INT');
        props.globals.initNode(path~ '/elapsed-time', 0, 'INT');
        props.globals.initNode(path~ '/text', "0' 0''", 'STRING');
    },
    listen: func(prop){
        var m = me;
        me.listener = setlistener(prop, func(_node){
            var state = _node.getValue();
            if(state == 0)
                m.stop();
            elsif(state == 1)
                m.start();
            elsif(state == 2)
                m.pause();
            elsif(state == 3)
                m.resume();
        }, 0, 0);
    },
    reset: func(){
        me.set('started', 0);
        me.set('paused', 0);
        me.set('started-at', 0);
        me.set('elapsed-time', 0);
        me.set('text', '');
    },
    start: func(){
        me.reset();
        var started_at = systime();
        me.set('started-at', started_at);
        me.update();
        me.timer = maketimer(1, me, me.update);
        me.timer.start();
        me.set('started', 1);
        me.set('paused', 0);
    },
    pause: func(){
        me.timer.stop();
        me.set('paused', 1);
    },
    resume: func(){
        me.timer.restart();
        me.set('paused', 0);
    },
    stop: func(){
        me.timer.stop();
        me.reset();
    },
    set: func(name, value){
        me.node.getNode(name).setValue(value);
    },
    get: func(name){
        me.node.getNode(name).getValue();
    },
    update: func(){
        var t = systime();
        var started_at = me.get('started-at');
        if(!started_at){
            started_at = systime();
            me.set('started-at', started_at);
        }
        var elapsed = t - started_at;
        me.set('elapsed-time', elapsed);
        me.updateText(elapsed);
    },
    updateText: func(elapsed){
        var d = elapsed;
        var h = int(d / 3600);
        d = math.fmod(d, 3600);
        var m = int(d / 60);
        d = math.fmod(d, 60);
        var s = d;
        var text = '';
        if(h > 0)
            text = sprintf("%02d %02d' %02d\"", h, m ,s);
        else
            text = sprintf("%d' %02d\"", m ,s);
        me.set('text', text);
    }
};

var chronos = [];

setlistener("sim/signals/fdm-initialized", func{
    fcu.init();
    append(chronos, Chrono.new(0, 'instrumentation/efis/inputs/CHRONO'));
    append(chronos, Chrono.new(1, 'instrumentation/efis[1]/inputs/CHRONO'));
    print("FCU initialized");
});
