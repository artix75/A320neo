var autoannunciator_active = "aircraft-config/auto-annunciator";
var landed = 0;

setlistener("engines/apu/running", func(){
    var running = getprop("engines/apu/running");
    var phase = getprop("flight-management/phase");
    if(running and phase == "T/O"){
        settimer(func(){
            if(getprop(autoannunciator_active)){
                setprop("sim/sound/welcome", 1);
            }
        }, 10);
    }
});

setlistener("controls/engines/engine[1]/cutoff-switch", func(){
    var cutoff = getprop("controls/engines/engine[1]/cutoff-switch");
    var phase = getprop("flight-management/phase");
    var wow = getprop("gear/gear/wow");
    if(!cutoff and phase == "T/O" and wow){
        settimer(func(){
            if(getprop(autoannunciator_active)){
                setprop("sim/sound/safety", 1);
            }
        }, 80);
    }
    elsif(cutoff and phase == "T/O" and wow and landed){
        settimer(func(){
            if(getprop(autoannunciator_active)){
                setprop("sim/sound/gate", 1);
            }
            landed = 0;
        }, 10);
    }
});

setlistener("flight-management/phase", func(){
    var phase = getprop("flight-management/phase");
    if(phase == 'APP'){
        settimer(func(){
            if(getprop(autoannunciator_active)){
                setprop("sim/sound/descent", 1);
            }
        }, 10);
    }
    elsif(phase == 'CLB'){
        settimer(func(){
            if(getprop(autoannunciator_active)){
                setprop("sim/sound/climb", 1);
            }
        }, 90);
    }
    elsif(phase == 'CRZ'){
        settimer(func(){
            if(getprop(autoannunciator_active)){
                setprop("sim/sound/cruise", 1);
            }
        }, 60);
    }
    elsif(phase == 'LANDED'){
        landed = 1;
        var ldg_chk = func(){
            if(getprop(autoannunciator_active)){
                var ias = getprop("/velocities/airspeed-kt");
                if(ias <= 40){
                    setprop("sim/sound/land", 1);
                } else {
                    settimer(ldg_chk, 10);
                }
            }
        };
        settimer(ldg_chk, 10);
    }
}, 0, 0);