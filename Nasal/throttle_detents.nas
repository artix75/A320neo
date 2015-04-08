var set_detent = func(detent_name){
    if(detent_name == 'rev'){
        if(getprop('/flight-management/control/a-thrust') != 'off')
            setprop('/flight-management/control/a-thrust', 'off');
        setprop('controls/engines/engine[0]/throttle', 0);
        setprop('controls/engines/engine[1]/throttle', 0);
        if(!getprop('controls/engines/engine/reverser'))
            reversethrust.togglereverser();
        var pos = getprop('controls/engines/detents/rev');
        interpolate('controls/engines/engine[0]/throttle-pos', pos, 0.2);
        interpolate('controls/engines/engine[1]/throttle-pos', pos, 0.2);
        #setprop('controls/engines/engine[0]/throttle', 0.6);
        #setprop('controls/engines/engine[1]/throttle', 0.6);
    } 
    elsif(detent_name == 'idle'){
        interpolate('controls/engines/engine[0]/throttle-pos', 0, 0.2);
        interpolate('controls/engines/engine[1]/throttle-pos', 0, 0.2);
        if(getprop('controls/engines/engine/reverser'))
            reversethrust.togglereverser();
    }
    else{
        if(getprop('controls/engines/engine/reverser')){
            setprop('controls/engines/engine[0]/throttle-pos', 0);
            setprop('controls/engines/engine[1]/throttle-pos', 0);
            reversethrust.togglereverser();
        }
        var pos = getprop('controls/engines/detents/'~ detent_name);
        interpolate('controls/engines/engine[0]/throttle-pos', pos, 0.2);
        interpolate('controls/engines/engine[1]/throttle-pos', pos, 0.2);
    }
}
