setprop('instrumentation/mcdu/prog/phase', 'PREFLIGHT');
setprop('instrumentation/mcdu/prog/opt-fl', 360);
setprop('instrumentation/mcdu/prog/max-fl', 380);

setlistener('flight-management/phase', func(n){
    var phase = n.getValue();
    var name = {
        'T/O': 'TAKEOFF',
        'CLB': 'CLIMB',
        'CRZ': 'CRUISE',
        'DES': 'DESCENT',
        'APP': 'APPROACH',
        'LANDED': 'APPROACH',
        'G/A': 'GO AROUND'
    }[phase];
    if(name == nil) name = '';
    setprop('instrumentation/mcdu/prog/phase', name);
}, 0, 0);