var detents_prop = 'controls/engines/detents/';
var athr = '/flight-management/control/a-thrust';
var athr_lever_pos_l = '/flight-management/control/a-thr-lever-pos[0]';
var athr_lever_pos_r = '/flight-management/control/a-thr-lever-pos[1]';
var left_lever_pos = 'controls/engines/engine[0]/throttle-pos';
var right_lever_pos = 'controls/engines/engine[1]/throttle-pos';
var DETENT_SOUND = 7;
var ENGINE_COUNT = 2;

#foreach(var propname; ['clb','flex']){
#    propname = detents_prop~ propname;
#    var detent_lvl = getprop(propname);
#    detent_lvl = int(detent_lvl * 100) / 100;
#    print("SETTING "~propname~" to "~detent_lvl);
#    setprop(propname, '');
#    setprop(propname, detent_lvl - 0.001);
#}

var detents = {
    REV: getprop(detents_prop~ 'rev'),
    IDLE: getprop(detents_prop~ 'idle'),
    CLB: getprop(detents_prop~ 'clb'),
    FLEX: getprop(detents_prop~ 'flex'),
    TOGA: getprop(detents_prop~ 'toga'),
};

setprop(athr_lever_pos_l, detents.CLB);
setprop(athr_lever_pos_r, detents.CLB);
setprop(left_lever_pos, 0);
setprop(right_lever_pos, 0);

var running_engines = [];
#var current_detent = [];

for(var i = 0; i < ENGINE_COUNT; i = i + 1){

    append(running_engines, 0);
    #append(current_detent, '');
    
    setlistener('engines/engine['~i~']/running', func(node){
        var running = node.getBoolValue();
        var idx = node.getParent().getIndex();
        running_engines[idx] = running;
    }, 0, 0);
    
    setlistener('controls/engines/engine['~i~']/throttle-pos', func(node){
        var idx = node.getParent().getIndex();
        var eng_running = running_engines[idx];
        if(!eng_running) return;
        var all_running = 1;
        for(var e = 0; e < ENGINE_COUNT; e = e + 1){
            if(e == idx) continue;
            var other_running = running_engines[e];
            if(!other_running){
                all_running = 0;
                break;
            }
        }
        var left_pos = getprop(left_lever_pos);
        var right_pos = getprop(right_lever_pos);
        var max_pos = (right_pos > left_pos ? right_pos : left_pos);
        var self_pos = node.getValue();
        if(self_pos == nil) self_pos = 0;
        var athr_status = getprop(athr);
        var detent = nil;
        var arming_pos = all_running ? detents.FLEX : detents.TOGA;
        var max_athr_pos = all_running ? detents.CLB : detents.FLEX;
        if(max_pos >= arming_pos){
            if(athr_status != 'armed'){
                setprop(athr, 'armed');
                disableThrustLock();
            }
        }
        elsif(max_pos <= detents.IDLE){
            if(athr_status != 'off'){
                setprop(athr, 'off');
            }
            disableThrustLock();
        } 
        elsif(max_pos > 0 and max_pos <= max_athr_pos) {
            if(getprop(athr) == 'armed'){
                setprop(athr, 'eng');
            }
        }
        elsif(max_pos > (max_athr_pos + 0.01) and athr_status == 'eng'){
            setprop(athr, 'armed');
            disableThrustLock();
        }
        elsif(max_pos > (max_athr_pos + 0.01)){
            disableThrustLock();
        }
        foreach(var detent_name; keys(detents)){
            var detent_lvl = detents[detent_name];
            if(int(self_pos * 100) == int(detent_lvl * 100)){
                utils.clickSound(DETENT_SOUND);
                break;
            }       
        }

        #setprop('flight-management/thrust-lock', 0);
    }, 0, 0);
}

var disableThrustLock = func(){
    var thr_lock = getprop('flight-management/thrust-lock');
    if (thr_lock) {
        var reason = getprop('flight-management/thrust-lock-reason');
        if (reason == 'THR') {
            setprop('flight-management/thrust-lock', 0);
            setprop('flight-management/thrust-lock-reason', '');
        }
    }
}

controls.incThrottle = func {
    var i = 0;
    var rev = getprop('controls/engines/engine/reverser');
    for(i = 0; i < ENGINE_COUNT; i = i + 1){
        var cur_throttle = getprop('controls/engines/engine['~i~']/throttle-pos');
        if(cur_throttle == nil) cur_throttle = 0;
        cur_throttle += arg[0];
        var min = (rev ? -0.63 : 0.0);
        var max = (rev ? 0.0 : 1.0);
        setprop('controls/engines/engine['~i~']/throttle-pos',
                cur_throttle < min ? min : cur_throttle > max ? max : cur_throttle
               );
    }
}


controls.throttleAxis = func(invert = 0){
    var val = cmdarg().getNode("setting").getValue();
    var rev = getprop('controls/engines/engine/reverser');
    var div = 2;
    if(invert) val = -val;
    if(rev) {
        #val = val * -1;
        div = -2;
    }
    val = (1 - val) / div;
    if(val < -0.63)
        val = -0.63;
    #print('AXIS: '~ val);
    for(i = 0; i < ENGINE_COUNT; i = i + 1){
        setprop('controls/engines/engine['~i~']/throttle-pos', val);
    }
}

controls.perEngineSelectedAxisHandler = func(n) {
    return
    func(index, invert = 0) {
        var val = cmdarg().getNode("setting").getValue();
        var rev = getprop('controls/engines/engine/reverser');
        var div = 2;
        if(invert) val = -val;
        if(rev) {
            div = -2;
        }
        val = (1 - val) / div;
        if(val < -0.63)
            val = -0.63;
        var pre = 'controls/engines/engine[';
        var post = ']/throttle-pos';
        if (typeof(index) == "scalar") {
            setprop(pre ~ index ~ post, val);
        } else {
            foreach (var e; index) {
                setprop(pre ~ e ~ post, val);
            }
        }
    };
}
