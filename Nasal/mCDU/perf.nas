setprop('/flight-management/spd-manager/climb/managed-speed', 250);
setprop('/flight-management/spd-manager/cruise/managed-speed', 0.78);
setprop('/flight-management/spd-manager/descent/managed-speed', 0.68);

var get_phase_name = func(phase){
    {
        'CLB': 'climb',
        'CRZ': 'cruise',
        'DES': 'descent'
    }[phase]
};

setlistener('flight-management/phase', func(n){
    var phase = n.getValue();
    var page = getprop("/instrumentation/mcdu/page");
    if(find('perf', page) == 0){
        if(phase == 'CLB' and (page == 'perf' or page == 'perf-crz'))
            page = 'perf-clb'
        elsif(phase == 'CRZ' and page == 'perf-clb')
            page = 'perf-crz';
        elsif(phase == 'DES' and page == 'perf-crz')
            page = 'perf-des';
        elsif(phase == 'APP')
            page = 'perf-app';
        elsif(phase == 'G/A')
            page = 'perf-ga';
        elsif(phase == 'T/O')
            page = 'perf';
        setprop("/instrumentation/mcdu/page", page);
    }
    var phase_name = {
        'CLB': 'climb',
        'CRZ': 'cruise',
        'DES': 'descent'
    }[phase];
    if(phase_name != nil){
        setprop('/flight-management/spd-manager/'~phase_name~'/managed-speed',
                getprop('/flight-management/fmgc-values/target-spd'));
    }
}, 0, 0);

setlistener('flight-management/fmgc-values/target-spd', func(n){
    var phase = getprop('flight-management/phase');
    var spd = n.getValue();
    var page = getprop("/instrumentation/mcdu/page");
    var phase_name = get_phase_name(phase);
    if(phase_name != nil){
        setprop('/flight-management/spd-manager/'~phase_name~'/managed-speed',
                spd);
    }
}, 0, 0);

setlistener('flight-management/control/spd-ctrl', func(n){
    var spd_ctrl = n.getValue();
    var phase = getprop('flight-management/phase');
    var str = {
        fmgc: 'MANAGED',
        'man-set': 'SELECTED'
    }[spd_ctrl];
    var phase_name = get_phase_name(phase);
    if(phase_name != nil){
        if(str == nil) str = 'SELECTED';
        setprop('/flight-management/spd-manager/'~ phase_name ~ '/mode', str);
    }
}, 0, 0);

setlistener('/instrumentation/fmc/acc-alt', func(n){
    var alt = n.getValue();
    var phase = getprop('flight-management/phase');
    if(phase != 'T/O') return;
    var profile = fmgc.fmgc_loop.spd_profile.CLB;
    if(alt == nil) alt = 1500;
    var spd = alt >= 10000 ? profile[0] : 250;
    setprop('/flight-management/spd-manager/climb/managed-speed', spd);
}, 0, 0);

setlistener('flight-management/crz_fl', func(n){
    var crz_fl = n.getValue();
    var crz_alt = int(crz_fl * 100);
    var mach_trans_alt = getprop('/instrumentation/fmc/mach-trans-alt');
    var phase = getprop('flight-management/phase');
    if(phase != 'T/O' and phase != 'CLB') return;
    var crz_profile = fmgc.fmgc_loop.spd_profile.CRZ;
    var des_profile = fmgc.fmgc_loop.spd_profile.DES;
    var spd_idx = crz_alt >= mach_trans_alt ? 1 : 0;
    var crz_spd = crz_profile[spd_idx];
    var des_spd = des_profile[spd_idx];
    setprop('/flight-management/spd-manager/cruise/managed-speed', crz_spd);
    setprop('/flight-management/spd-manager/descent/managed-speed', des_spd);
}, 0, 0);

setlistener("/flight-management/settings/acc-alt", func(n){
    var acc_alt = n.getValue();
    var thr_red = getprop("/flight-management/settings/thr-red");
    if(thr_red == nil or !thr_red) thr_red = acc_alt;
    setprop('instrumentation/fmc/thr-red-acc', thr_red ~ '/' ~ acc_alt);
}, 0, 0);

setlistener("/flight-management/settings/thr-red", func(n){
    var thr_red = n.getValue();
    var acc_alt = getprop("/flight-management/settings/acc-alt");
    if(acc_alt == nil or !acc_alt) acc_alt = thr_red;
    setprop('instrumentation/fmc/thr-red-acc', thr_red ~ '/' ~ acc_alt);
}, 0, 0);

setlistener("/flight-management/settings/ga-acc-alt", func(n){
    var acc_alt = n.getValue();
    var thr_red = getprop("/flight-management/settings/ga-thr-red");
    if(thr_red == nil or !thr_red) thr_red = acc_alt;
    setprop('instrumentation/fmc/ga-thr-red-acc', thr_red ~ '/' ~ acc_alt);
}, 0, 0);

setlistener("/flight-management/settings/ga-thr-red", func(n){
    var thr_red = n.getValue();
    var acc_alt = getprop("/flight-management/settings/ga-acc-alt");
    if(acc_alt == nil or !acc_alt) acc_alt = thr_red;
    setprop('instrumentation/fmc/ga-thr-red-acc', thr_red ~ '/' ~ acc_alt);
}, 0, 0);

