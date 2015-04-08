setprop('/instrumentation/mcdu/overfly-mode', 0);
setprop('/instrumentation/mcdu/clear-mode', 0);

var clear_inp = func {
    setprop("/instrumentation/mcdu/input", "");
};

setlistener("/instrumentation/mcdu/input", func(n){
    var input = n.getValue();
    if(size(input) > 0){
        setprop('/instrumentation/mcdu/clear-mode', 0);
        setprop('/instrumentation/mcdu/overfly-mode', 0);
    }
}, 0, 0);

