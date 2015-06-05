var KELVIN_K = 273.15;
var FULL_N1 = 1.0;

var engine_loop = {
    UPDATE_INTERVAL: 0.1,
    init: func () {
        me.timer = maketimer(me.UPDATE_INTERVAL, me, me.update);
        me.timer.start();
    },
    update: func() {
        me.flex_to_temp = getprop('/instrumentation/fmc/flex-to-temp');
        me.use_flex_temp = (me.flex_to_temp > -100);
        if (me.use_flex_temp) {
            var ambient_temp = getprop('environment/temperature-degc');
            me.flex_thr = me.calc_n1(ambient_temp, me.flex_to_temp);
        } else {
            me.flex_thr = thrust_levers.detents.FLEX;
        }
        setprop('engines/thrust-control/use-flex', me.use_flex_temp);
        setprop('engines/thrust-control/flex-thr', me.flex_thr);
    },
    calc_n1: func(ambient_temp, flex_temp) {
        ambient_temp = ambient_temp + KELVIN_K;
        flex_temp = flex_temp + KELVIN_K;
        var n1 = FULL_N1 * math.sqrt(ambient_temp / flex_temp);
        if (n1 > FULL_N1) n1 = FULL_N1;
        if (n1 < thrust_levers.detents.CLB) n1 = thrust_levers.detents.CLB;
        return n1;
    }
};

setlistener("sim/signals/fdm-initialized", func (){
    engine_loop.init();
    print("Engine Loop initialized");
});