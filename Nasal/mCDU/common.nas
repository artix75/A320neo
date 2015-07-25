var MSG_LEVEL_NORMAL = 0;
var MSG_LEVEL_WARN = 1;

var MSG = {
    FORMAT_ERROR: 'FORMAT ERROR',
    NOT_IN_DB: 'NOT IN DATABASE',
    DECELERATE: 'DECELERATE'
};

setprop('/instrumentation/mcdu/overfly-mode', 0);
setprop('/instrumentation/mcdu/clear-mode', 0);

var clear_inp = func {
    setprop("/instrumentation/mcdu/input", "");
};


var display_message = func(msg, level = 0){
    setprop("/instrumentation/mcdu/s-pad-msg", msg);
    setprop("/instrumentation/mcdu/s-pad-warn-level", level);
    setprop('/instrumentation/mcdu/hide-message', 0);
}

setlistener("/instrumentation/mcdu/input", func(n){
    var input = n.getValue();
    if(size(input) > 0){
        setprop('/instrumentation/mcdu/clear-mode', 0);
        setprop('/instrumentation/mcdu/overfly-mode', 0);
        setprop('/instrumentation/mcdu/hide-message', 1);
        if(!getprop("/instrumentation/mcdu/s-pad-warn-level"))
            setprop("/instrumentation/mcdu/s-pad-msg", '');
    } else {
        setprop('/instrumentation/mcdu/hide-message', 0);
    }
}, 0, 0);

